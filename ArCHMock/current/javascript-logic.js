function Logger(logString) {
//    var date = new Date();
//    var milliseconds = date.getMilliseconds();
//    var millisecondsDigits = ('' + milliseconds).length;
//    if (millisecondsDigits < 3) {
//        milliseconds = millisecondsDigits < 2 ? '00' + milliseconds : '0' + milliseconds;
//    }
//    var timeString = date.toLocaleTimeString();
//    timeString = timeString.replace(/\d?\d:\d\d:\d\d/, function(time) {
//                                    return time + '.' + milliseconds;
//                                    });
//    var timeStamp = date.toLocaleDateString() + ' ' + timeString;
//    
//    logString = timeStamp + ": " + logString;
    window.console.log(logString);
};
$w('debug info warn error').each(function(level) {
                                 Logger[level] = window.console 
                                 ? function(logString) { Logger(level.toUpperCase() + ': ' + logString); }
                                 : function(logString) {};
                                 });

var highlighter = new function Highlighter() {
	Event.observe(window, 'scroll', function(event) { 
                  this.isPaused = true;
                  }.bind(this));
    
    this.highlightedElementIdTemplate = new Template('chm-highlighted-#{id}');
    this.nodesThreshold = 60;
	
	this.scheduledHighlighting = null;
	this.scheduledHighlightsRemoving = null;
    this.scheduledScrollingToHighlight = null;
    
    this.isHighlighted = false;
	this.isHighlighting = false;
	this.isRemovingHighlights = false;
	this.isCancelled = false;
	this.isPaused = false;
	
	this.indexOfHighlightedElementInFocus = null;
	
	this.highlight = function(text) {
        if (this.isHighlighting) {
            this.isCancelled = true;
            this.scheduledHighlighting = function() { this.startHighlighting(text); }.bind(this);
        } 
        else if (this.isRemovingHighlights) {
            this.scheduledHighlighting = function() { this.startHighlighting(text); }.bind(this);
        }
        else {
            this.startHighlighting(text);
        }
    };
    
    this.startHighlighting = function(text) {
        this.scheduledHighlighting = null;
        
        var bodyNode = document.body;
        if (!bodyNode) {
            Logger.error("Body node not found. Can't proceed with highlighting");
            return;
        }
        
        this.prepareHighlightPattern(text);
        
        this.initHighlighting();
        
        this.nodesToProcess = $A(bodyNode.childNodes); 
        this.isHighlighting = true;
        setTimeout(this.processNodes.bind(this), 0);
//        Logger.debug('Highlighting started');
    };
    
    this.initHighlighting = function() {
        this.replacements = [];
    	this.nodesToProcess = [];
    	
    	this.isHighlighting = false;
    	this.isHighlighted = false;
    	this.isRemovingHighlights = false;
    	this.isPaused = false;
    	this.highlightsCount = 0;
    	
    	this.indexOfHighlightedElementInFocus = null;	
    };
    
    this.prepareHighlightPattern = function(text) {
        this.text = text;
        
        var patternParts = [];
        
        var words = text.split(/\s+/).findAll(function(text) { return text != ''; });
        // Words that constitute pattern should be sorted like following:
        // ['perl', 'pe', 'p']
        words.sort().reverse();
        
        var escapedWords = words.collect(function(word) {
                                         if (!/[a-zA-Z0-9]/.test(word)) { 
                                         return RegExp.escape(word); 
                                         }
                                         
                                         var easiedWord = word.replace(/[^a-zA-Z0-9]/g, function(match) {
                                                                       return /[.*+?^${}()|[\]\/\\]/.test(match) ? '(?:\\' + match + ')?' : match + '?';
                                                                       });
                                         
                                         return null != easiedWord ? easiedWord : word;
                                         });
        patternParts.push.apply(patternParts, escapedWords);
        
        var wordsParts = words.collect(function(word) {
                                       if (/[^a-zA-Z0-9]/.test(word)) {
                                       return word.split(/[^a-zA-Z0-9]+/).findAll(function(part) { return '' !== part; });
                                       }
                                       else {
                                       return null;
                                       }
                                       }).findAll(function(part) { return null !== part ; }).flatten();
        wordsParts.sort().reverse();
        patternParts.push.apply(patternParts, wordsParts);
        
        this.wordsRegExp = new RegExp(patternParts.join('|'), 'gim');
//        Logger.debug("Words RegExp: '" + this.wordsRegExp.source + "'");
        
    };
    
    this.processNodes = function() {
        if (this.isCancelled) {
//            Logger.debug('Highlighting cancelled');
            return this.nodesProcessingFinished();
        }   
        
        var nodesThreshold = this.nodesThreshold;
        while (nodesThreshold--) {
            if (this.isPaused) {
                break;
            }
            if (!this.processNode()) {
                return this.nodesProcessingFinished();
            }
        }
        
        if (this.nodesToProcess.length != 0) {
            if (this.scheduledScrollingToHighlight && this.isHighlighted) {
                this.scheduledScrollingToHighlight();
            }
            var timeout = 0;
            if (this.isPaused) {
                timeout = 100;
                this.isPaused = false;
//                Logger.debug('Making pause for ' + timeout + ' ms');
            }
            setTimeout(this.processNodes.bind(this), timeout);
        }
        else {
            this.nodesProcessingFinished();
        }
    };
    
    this.nodesProcessingFinished = function() {
        this.isCancelled = false;
        this.isHighlighting = false;
//        Logger.debug('Highlighting ended');

        if (this.scheduledScrollingToHighlight && this.isHighlighted) {
            this.scheduledScrollingToHighlight();
        }
        
        if (this.scheduledHighlightsRemoving) {
//            Logger.debug('Running scheduled highlights removing');
            setTimeout(this.scheduledHighlightsRemoving, 0);
        }
        else if (this.scheduledHighlighting) {
//            Logger.debug('Running scheduled highlighting');
            setTimeout(this.scheduledHighlighting, 0);
        }
    };
    
    this.processNode = function() {
        if (0 == this.nodesToProcess.length) {
            return false;
        }
        
        var currentNode = this.nodesToProcess.shift();
        
        if (Node.TEXT_NODE == currentNode.nodeType) {
            this.processTextNode(currentNode);
        }
        else {
            var nodeName = currentNode.nodeName;
            if (!/^(script|style)$/i.test(nodeName)) {
                var childNodes = $A(currentNode.childNodes);
                this.nodesToProcess.unshift.apply(this.nodesToProcess, childNodes);
            }
        }                           
        
        return this.nodesToProcess.length != 0;
    };
    
    this.processTextNode = function(node) {
        var text = node.nodeValue;
        
        var highlightedText = '';
        var previousLastIndex = 0;
        this.wordsRegExp.lastIndex = 0;
        
        var match;
        while (match = this.wordsRegExp.exec(text)) {
            // Logger.debug('Match: ' + match.inspect() + ', lastIndex: ' + this.wordsRegExp.lastIndex + ', match length: ' + match[0].length);
            var plainChunk = text.substring(previousLastIndex, this.wordsRegExp.lastIndex - match[0].length);
            // Logger.debug("Plain chunk: '" + plainChunk + "'");
            highlightedText = highlightedText +
            plainChunk.escapeHTML() + 
            '<span class="highlighted-chunk" id="' + 
            this.highlightedElementIdTemplate.evaluate({id: this.highlightsCount++}) + 
            '" style="background-color: rgba(253, 255, 0, 1); -webkit-border-radius: 3px; border-width: 0">' + 
            match[0].escapeHTML() + 
            '</span>';
            previousLastIndex = this.wordsRegExp.lastIndex;

            this.isHighlighted = true;
        }
        if (highlightedText) {
            highlightedText = highlightedText + text.substring(previousLastIndex, text.length).escapeHTML();
            // Logger.debug("Matched text: '" + text + "'");
            // Logger.debug("Highlighted text: '" + highlightedText + "'");
            var highlightedNode = document.createElement('span');
            this.replacements.push({
                                   plain:       node.parentNode.replaceChild(highlightedNode, node), 
                                   highlighted: highlightedNode
                                   });
            highlightedNode.innerHTML = highlightedText;
        }
    };
    
    this.removeHighlights = function() {
        if (this.isHighlighting) {
            this.isCancelled = true;
            this.scheduledHighlightsRemoving = this.startHighlightsRemoving.bind(this);
        }
        else if (!this.isRemovingHighlights) {
            this.startHighlightsRemoving();
        }
    };   
    
    this.startHighlightsRemoving = function() {
        this.scheduledHighlightsRemoving = null;
        
    	if (!this.isHighlighted) {
    		return;
    	}
        
//        Logger.debug('Removing highlights');
        this.isRemovingHighlights = true;
        this.replacements.each(function(nodesPair) {
                               nodesPair.highlighted.parentNode.replaceChild(nodesPair.plain, nodesPair.highlighted);
                               });
    	this.isHighlighted = false;
//        Logger.debug('Highlights removed');
        
        this.isRemovingHighlights = false;
        if (this.scheduledHighlighting) {
//            Logger.debug('Starting scheduled higlighting');
            setTimeout(this.scheduledHighlighting, 0);
        }
    };
    
    this.scrollToFirstHighlight = function() {
        this.scheduledScrollingToHighlight = null;
        
        var highlightedElement = $(this.highlightedElementIdTemplate.evaluate({id: 0}));
        
        if (highlightedElement) {
            this.scrollToElement(highlightedElement);
            this.indexOfHighlightedElementInFocus = 0;
        }
        else {
            Logger.warn('Angry beep');
            // TODO: Angry beep
        }
    };
    
    this.scrollToNextHighlight = function() {
        this.scheduledScrollingToHighlight = null;
        
        this.scrollToHighlight(this.indexOfHighlightedElementInFocus + 1);
    };
    
    this.scrollToPreviousHighlight = function() {
        this.scheduledScrollingToHighlight = null;
        
        this.scrollToHighlight(this.indexOfHighlightedElementInFocus - 1);
    };
    
    this.scrollToHighlight = function(index) {           
        this.scheduledScrollingToHighlight = null;
        
        if (null === this.indexOfHighlightedElementInFocus) {
            return this.scrollToFirstHighlight();
        }
        
        if (index >= this.highlightsCount) {
            return this.scrollToFirstHighlight();
        }
        else if (index < 0) {
            return this.scrollToHighlight(this.highlightsCount - 1);
        }
        
        var highlightedElement = $(this.highlightedElementIdTemplate.evaluate({id: index}));
        
        if (highlightedElement) {
            this.scrollToElement(highlightedElement);
            this.indexOfHighlightedElementInFocus = index;
        }
        else {
            Logger.error('Invalid highlighted element');
        }
    };
    
    this.scrollToElement = function(element) {
        Effect.ScrollTo(element, {duration: 0.1, offset: -10, afterFinishInternal: function() {
                        var cloneEl = element.cloneNode(true);
                        cloneEl.setAttribute('id', 'to-puff-' + element.getAttribute('id'));
                        element.parentNode.insertBefore(cloneEl, element);
                        cloneEl.absolutize();
                        // Logger.debug("Element to puff: '" + $(copy).inspect());
                        Effect.Puff(cloneEl);
                        // Logger.debug("Effect applied");
                        }});
    };
    
    this.canScrollBetweenHighlights = function() {
        return this.isHighlighted; 
    };
    
    this.scheduleScrollingToHighlight = function() {
        if (this.isHighlighting) {
            this.scheduledScrollingToHighlight = this.scrollToNextHighlight.bind(this);
        }
        else if (this.isHighlighted) {
            this.scrollToNextHighlight();
        }
    }
};

Event.observe(window, 'scroll', function(event) {
              chmDocument.setCurrentSectionScrollOffset_(Object.toJSON(document.viewport.getScrollOffsets()));
              });
Event.observe(window, 'unload', function(event) {
              chmDocument.setCurrentSectionScrollOffset_('[0, 0]');
              highlighter.removeHighlights();
              });
window.scrollTo.apply(window, chmDocument.currentSectionScrollOffset().evalJSON(true));
