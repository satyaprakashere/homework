/**
 * Canvas Text Editor Core
 * Features: Multi-cursor, Word-wrapping, Premium rendering
 * Optimizations: Lazy rendering, Layout caching
 */

class CanvasEditor {
    /**
     * Initializes the CanvasEditor instance.
     */
    constructor() {
        this.canvas = document.getElementById('editor-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.input = document.getElementById('hidden-input');
        
        // Editor State
        this.lines = [
            "Welcome to the Canvas Text Editor!",
            "",
            "This editor features:",
            "• High-performance Canvas rendering",
            "• Dynamic Word-Wrapping",
            "• Multi-cursor support (Alt + Click)",
            "• Premium Dark Glassmorphism UI",
            "",
            "Start typing here... or try creating multiple cursors!"
        ]; 
        this.cursors = [{ line: 0, col: 0 }]; 
        this.scrollOffset = 0;
        this.lineHeight = 28;
        this.fontSize = 16;
        this.padding = 20;
        this.gutterWidth = 60;
        
        // Syntax Colors
        this.colors = {
            keyword: "#ff7b72",
            string: "#a5d6ff",
            comment: "#8b949e",
            number: "#d2a8ff",
            func: "#d2a8ff",
            text: "#c9d1d9",
            gutter: "#484f58"
        };
        
        // Persistence
        this.apiBase = "http://localhost:8081/api";
        this.saveTimeout = null;

        // Flags
        this.needsRender = true;
        this.needsLayout = true;
        this.cachedVisualLines = [];
        this.isFocused = false;
        
        // Configuration
        this.fontFamily = "'JetBrains Mono', monospace";
        this.cursorBlink = true;
        this.lastBlinkTime = 0;
        this.blinkInterval = null;
        
        this.init();
        this.load();
    }

    /**
     * Asynchronously loads the document content from the backend API.
     * @returns {Promise<void>}
     */
    async load() {
        try {
            const response = await fetch(`${this.apiBase}/document`);
            if (!response.ok) return;
            const data = await response.json();
            if (data.content !== undefined) {
                this.lines = data.content.split('\n');
                if (this.lines.length === 0) this.lines = [""];
            }
            this.triggerLayout();
            this.updateStats();
        } catch (e) {
            console.warn("Backend not available, persistence disabled.");
        }
    }

    /**
     * Saves the document content to the backend API with a debounce timeout.
     */
    save() {
        if (this.saveTimeout) clearTimeout(this.saveTimeout);
        this.saveTimeout = setTimeout(async () => {
            try {
                await fetch(`${this.apiBase}/document`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ content: this.lines.join('\n') })
                });
            } catch (e) {
                console.error("Failed to save document:", e);
            }
        }, 1000);
    }

    /**
     * Initializes event listeners, window resizing, and the rendering loop.
     */
    init() {
        this.resize();
        window.addEventListener('resize', () => {
            this.resize();
            this.triggerLayout();
        });
        
        // Interaction handle
        this.canvas.addEventListener('mousedown', (e) => this.handleMouseDown(e));
        this.canvas.addEventListener('wheel', (e) => this.handleWheel(e), { passive: false });
        
        this.input.addEventListener('input', (e) => this.handleInput(e));
        this.input.addEventListener('keydown', (e) => this.handleKeyDown(e));
        this.input.addEventListener('paste', (e) => this.handlePaste(e));
        
        this.input.addEventListener('focus', () => {
            this.isFocused = true;
            this.startBlinking();
            this.triggerRender();
        });
        this.input.addEventListener('blur', () => {
            this.isFocused = false;
            this.stopBlinking();
            this.triggerRender();
        });

        // Refocus on container click
        const container = document.getElementById('editor-host');
        container.addEventListener('mousedown', (e) => {
            if (e.target !== this.canvas) {
                this.input.focus();
            }
        });

        // Global click to ensure focus if clicking empty areas
        document.addEventListener('mousedown', (e) => {
            // Only refocus if the click is within the body but not on other interactive elements
            // This is a safety net
            if (e.target === document.body || e.target === document.documentElement) {
                this.input.focus();
            }
        });
        
        // Animation loop
        requestAnimationFrame((t) => this.render(t));
        
        // Focus initial
        this.input.focus();
        this.updateStats();
    }

    /**
     * Triggers a re-render of the canvas by setting the needsRender flag to true.
     */
    triggerRender() {
        this.needsRender = true;
    }

    /**
     * Triggers a layout recalculation and a subsequent render.
     */
    triggerLayout() {
        this.needsLayout = true;
        this.needsRender = true;
    }

    /**
     * Starts the cursor blinking animation.
     */
    startBlinking() {
        if (this.blinkInterval) return;
        this.blinkInterval = setInterval(() => {
            this.cursorBlink = !this.cursorBlink;
            this.triggerRender();
        }, 530);
    }

    /**
     * Stops the cursor blinking animation.
     */
    stopBlinking() {
        clearInterval(this.blinkInterval);
        this.blinkInterval = null;
        this.cursorBlink = false;
        this.triggerRender();
    }

    /**
     * Resizes the canvas to fit its container and accounts for device pixel ratio.
     */
    resize() {
        const dpr = window.devicePixelRatio || 1;
        const rect = this.canvas.getBoundingClientRect();
        
        this.canvas.width = rect.width * dpr;
        this.canvas.height = rect.height * dpr;
        this.ctx.scale(dpr, dpr);
        
        this.width = rect.width;
        this.height = rect.height;
        this.triggerLayout();
    }

    /**
     * Handles the mouse wheel event for scrolling the editor.
     * @param {WheelEvent} e - The wheel event.
     */
    handleWheel(e) {
        e.preventDefault();
        this.scrollOffset -= e.deltaY;
        
        // Constrain scroll
        const visualLines = this.getVisualLines();
        const totalHeight = visualLines.length > 0 ? (visualLines[visualLines.length - 1].y + this.lineHeight) : 0;
        const maxScroll = Math.max(0, totalHeight - this.height + this.padding);
        
        this.scrollOffset = Math.max(-maxScroll, Math.min(this.padding, this.scrollOffset));
        this.triggerRender();
    }

    /**
     * Tokenizes a given string into syntax tokens based on predefined rules.
     * @param {string} text - The text to tokenize.
     * @returns {Array<{type: string, text: string}>} The resulting tokens.
     */
    tokenize(text) {
        const tokens = [];
        const rules = [
            { type: 'comment', regex: /^\/\/.*|^\/\*[\s\S]*?\*\// },
            { type: 'string', regex: /^"[^"]*"|^'[^']*'|^`[^`]*`/ },
            { type: 'keyword', regex: /^(?:await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|false|finally|for|function|if|implements|import|in|instanceof|interface|let|new|null|package|private|protected|public|return|static|super|switch|this|throw|true|try|typeof|var|void|while|with|yield)\b/ },
            { type: 'number', regex: /^\d+/ },
            { type: 'func', regex: /^[a-zA-Z_]\w*(?=\s*\()/ },
            { type: 'text', regex: /^.+?/ }
        ];

        let remaining = text;
        while (remaining.length > 0) {
            let matched = false;
            for (const rule of rules) {
                const match = remaining.match(rule.regex);
                if (match) {
                    tokens.push({ type: rule.type, text: match[0] });
                    remaining = remaining.slice(match[0].length);
                    matched = true;
                    break;
                }
            }
            if (!matched) {
                tokens.push({ type: 'text', text: remaining[0] });
                remaining = remaining.slice(1);
            }
        }
        return tokens;
    }

    /**
     * Calculates and caches the visual lines, handling word wrapping and tokenization.
     * @returns {Array<{text: string, logicalLine: number, startCol: number, endCol: number, y: number, tokens: Array}>} An array of visual fragments.
     */
    getVisualLines() {
        if (!this.needsLayout) return this.cachedVisualLines;

        this.ctx.font = `${this.fontSize}px ${this.fontFamily}`;
        const visualLines = [];
        const maxWidth = Math.max(100, this.width - this.padding - this.gutterWidth - 20);
        let currentY = this.padding;

        this.lines.forEach((line, index) => {
            if (line === "") {
                visualLines.push({
                    text: "",
                    logicalLine: index,
                    startCol: 0,
                    endCol: 0,
                    y: currentY,
                    tokens: []
                });
                currentY += this.lineHeight;
                return;
            }

            let start = 0;
            while (start < line.length) {
                let low = start;
                let high = line.length;
                let bestEnd = start + 1;

                while (low <= high) {
                    let mid = Math.floor((low + high) / 2);
                    let segment = line.substring(start, mid);
                    if (this.ctx.measureText(segment).width <= maxWidth) {
                        bestEnd = mid;
                        low = mid + 1;
                    } else {
                        high = mid - 1;
                    }
                }

                const visualText = line.substring(start, bestEnd);
                visualLines.push({
                    text: visualText,
                    logicalLine: index,
                    startCol: start,
                    endCol: bestEnd,
                    y: currentY,
                    tokens: this.tokenize(visualText)
                });
                
                start = bestEnd;
                currentY += this.lineHeight;
            }
        });

        this.cachedVisualLines = visualLines;
        this.needsLayout = false;
        return visualLines;
    }

    /**
     * Handles the input event when text is entered into the hidden input field.
     * @param {Event} e - The input event.
     */
    handleInput(e) {
        const chars = this.input.value;
        if (!chars) return;

        this.cursors.forEach(cursor => {
            const line = this.lines[cursor.line];
            this.lines[cursor.line] = line.slice(0, cursor.col) + chars + line.slice(cursor.col);
            cursor.col += chars.length;
        });

        this.input.value = "";
        this.triggerLayout();
        this.updateStats();
        this.save();
    }

    /**
     * Handles keydown events for special keys like Enter, Tab, Backspace, and Arrow keys.
     * @param {KeyboardEvent} e - The keydown event.
     */
    handleKeyDown(e) {
        let changed = false;
        if (e.key === 'Enter') {
            e.preventDefault();
            this.cursors.forEach(cursor => {
                const line = this.lines[cursor.line];
                const head = line.slice(0, cursor.col);
                const tail = line.slice(cursor.col);
                
                // Auto-indentation
                const match = head.match(/^\s*/);
                const indent = match ? match[0] : "";
                
                this.lines[cursor.line] = head;
                this.lines.splice(cursor.line + 1, 0, indent + tail);
                
                cursor.line++;
                cursor.col = indent.length;
            });
            changed = true;
        } else if (e.key === 'Tab') {
            e.preventDefault();
            this.cursors.forEach(cursor => {
                const line = this.lines[cursor.line];
                this.lines[cursor.line] = line.slice(0, cursor.col) + "    " + line.slice(cursor.col);
                cursor.col += 4;
            });
            changed = true;
        } else if (e.key === 'Backspace') {
            this.cursors.forEach(cursor => {
                const line = this.lines[cursor.line];
                if (cursor.col > 0) {
                    this.lines[cursor.line] = line.slice(0, cursor.col - 1) + line.slice(cursor.col);
                    cursor.col--;
                } else if (cursor.line > 0) {
                    const prevLine = this.lines[cursor.line - 1];
                    const currentColContent = this.lines[cursor.line];
                    cursor.col = prevLine.length;
                    this.lines[cursor.line - 1] = prevLine + currentColContent;
                    this.lines.splice(cursor.line, 1);
                    cursor.line--;
                }
            });
            changed = true;
        } else if (e.key === 'ArrowLeft') {
            this.cursors.forEach(cursor => {
                if (cursor.col > 0) cursor.col--;
                else if (cursor.line > 0) {
                    cursor.line--;
                    cursor.col = this.lines[cursor.line].length;
                }
            });
            changed = true;
        } else if (e.key === 'ArrowRight') {
            this.cursors.forEach(cursor => {
                if (cursor.col < this.lines[cursor.line].length) cursor.col++;
                else if (cursor.line < this.lines.length - 1) {
                    cursor.line++;
                    cursor.col = 0;
                }
            });
            changed = true;
        } else if (e.key === 'ArrowUp') {
            this.cursors.forEach(cursor => {
                if (cursor.line > 0) cursor.line--;
                cursor.col = Math.min(cursor.col, this.lines[cursor.line].length);
            });
            changed = true;
        } else if (e.key === 'ArrowDown') {
            this.cursors.forEach(cursor => {
                if (cursor.line < this.lines.length - 1) cursor.line++;
                cursor.col = Math.min(cursor.col, this.lines[cursor.line].length);
            });
            changed = true;
        }
        
        if (changed) {
            this.triggerLayout();
            this.updateStats();
            this.save();
        }
    }

    /**
     * Handles mouse down events on the canvas to place cursors.
     * @param {MouseEvent} e - The mouse down event.
     */
    handleMouseDown(e) {
        e.preventDefault(); // Prevent canvas from taking focus
        const x = e.offsetX;
        const y = e.offsetY - this.scrollOffset;

        const visualLines = this.getVisualLines();
        let found = false;

        const contentX = x - this.gutterWidth;

        for (const vLine of visualLines) {
            const lineTop = vLine.y - this.lineHeight;
            const lineBottom = vLine.y;
            
            if (y >= lineTop && y <= lineBottom) {
                let col = vLine.startCol;
                let minDist = Infinity;
                for (let i = 0; i <= vLine.text.length; i++) {
                    const measure = this.ctx.measureText(vLine.text.substring(0, i));
                    const dist = Math.abs(this.padding + measure.width - contentX);
                    if (dist < minDist) {
                        minDist = dist;
                        col = vLine.startCol + i;
                    }
                }

                if (e.altKey) {
                    this.cursors.push({ line: vLine.logicalLine, col });
                } else {
                    this.cursors = [{ line: vLine.logicalLine, col }];
                }
                found = true;
                break;
            }
        }
        
        if (!found && !e.altKey) {
            const lastLine = this.lines.length - 1;
            this.cursors = [{ line: lastLine, col: this.lines[lastLine].length }];
        }

        this.input.focus();
        this.triggerRender();
        this.updateStats();
    }
    
    /**
     * Handles the paste event.
     * @param {ClipboardEvent} e - The paste event.
     */
    handlePaste(e) {
        e.preventDefault();
        const text = e.clipboardData.getData('text');
        this.cursors.forEach(cursor => {
            const line = this.lines[cursor.line];
            this.lines[cursor.line] = line.slice(0, cursor.col) + text + line.slice(cursor.col);
            cursor.col += text.length;
        });
        this.triggerLayout();
        this.updateStats();
        this.save();
    }

    /**
     * Updates the status bar with character count, word count, and current cursor position.
     */
    updateStats() {
        document.getElementById('char-count').innerText = `${this.lines.join('').length} characters`;
        const words = this.lines.join(' ').split(/\s+/).filter(Boolean).length;
        document.getElementById('word-count').innerText = `${words} words`;
        const primary = this.cursors[0];
        document.getElementById('cursor-info').innerText = `Line ${primary.line + 1}, Col ${primary.col + 1}`;
    }

    /**
     * The main rendering loop that paints the editor's UI on the canvas.
     * @param {number} time - The current timestamp from requestAnimationFrame.
     */
    render(time) {
        if (!this.needsRender) {
            requestAnimationFrame((t) => this.render(t));
            return;
        }

        this.ctx.clearRect(0, 0, this.width, this.height);
        
        const visualLines = this.getVisualLines();
        this.ctx.font = `${this.fontSize}px ${this.fontFamily}`;
        
        this.ctx.save();
        this.ctx.translate(0, this.scrollOffset); 

        // Draw Gutter
        this.ctx.fillStyle = "rgba(0,0,0,0.2)";
        this.ctx.fillRect(0, -this.scrollOffset, this.gutterWidth, this.height);
        this.ctx.strokeStyle = "rgba(255,255,255,0.05)";
        this.ctx.beginPath();
        this.ctx.moveTo(this.gutterWidth, -this.scrollOffset);
        this.ctx.lineTo(this.gutterWidth, this.height - this.scrollOffset);
        this.ctx.stroke();

        // Draw Text and Line Numbers
        visualLines.forEach(vLine => {
            const screenY = vLine.y + this.scrollOffset;
            if (screenY > -this.lineHeight && screenY < this.height + this.lineHeight) {
                // Line Number
                if (vLine.startCol === 0) {
                    this.ctx.fillStyle = this.colors.gutter;
                    this.ctx.font = `12px ${this.fontFamily}`;
                    const num = (vLine.logicalLine + 1).toString();
                    const numWidth = this.ctx.measureText(num).width;
                    this.ctx.fillText(num, this.gutterWidth - 15 - numWidth, vLine.y);
                    this.ctx.font = `${this.fontSize}px ${this.fontFamily}`;
                }

                // Tokens
                let currentX = this.gutterWidth + this.padding;
                vLine.tokens.forEach(token => {
                    this.ctx.fillStyle = this.colors[token.type] || this.colors.text;
                    this.ctx.fillText(token.text, currentX, vLine.y);
                    currentX += this.ctx.measureText(token.text).width;
                });
            }
        });

        // Draw Cursors
        if (this.cursorBlink && this.isFocused) {
            this.ctx.fillStyle = "#58a6ff";
            this.cursors.forEach(cursor => {
                const vLine = visualLines.find(vl => 
                    vl.logicalLine === cursor.line && 
                    cursor.col >= vl.startCol && 
                    (cursor.col < vl.endCol || (cursor.col === vl.endCol && vl.endCol === this.lines[cursor.line].length))
                );

                if (vLine) {
                    const textBefore = vLine.text.substring(0, cursor.col - vLine.startCol);
                    const offset = this.ctx.measureText(textBefore).width;
                    
                    this.ctx.shadowBlur = 10;
                    this.ctx.shadowColor = "rgba(88, 166, 255, 0.6)";
                    this.ctx.fillRect(this.gutterWidth + this.padding + offset, vLine.y - this.fontSize, 2, this.fontSize + 4);
                    this.ctx.shadowBlur = 0;
                }
            });
        }

        this.ctx.restore();
        this.needsRender = false;
        requestAnimationFrame((t) => this.render(t));
    }
}

// Start the editor
window.addEventListener('DOMContentLoaded', () => {
    window.editor = new CanvasEditor();
});
