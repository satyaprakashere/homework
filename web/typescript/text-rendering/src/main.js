import CanvasKitInit from 'canvaskit-wasm';
// Helper for 'using' keyword compatibility
const disposable = (obj) => {
    obj[Symbol.dispose] = () => obj.delete();
    return obj;
};
async function runCustomFontDemo() {
    const CK = await CanvasKitInit({
        locateFile: (file) => `https://unpkg.com/canvaskit-wasm@latest/bin/full/${file}`
    });
    // 1. Load Font Data from URL
    const fontResponse = await fetch('https://storage.googleapis.com/skia-cdn/google-fonts/NotoSans-Regular.ttf');
    const fontBuffer = await fontResponse.arrayBuffer();
    // 2. Setup WebGPU (M2 Pro optimized)
    const adapter = await navigator.gpu.requestAdapter();
    const device = await adapter.requestDevice();
    const canvasElement = document.getElementById('skia-canvas');
    const surface = CK.MakeGPUCanvasSurface(device, canvasElement);
    // 3. Register Font and Render
    renderWithCustomFont(CK, surface, fontBuffer);
}
function renderWithCustomFont(CK, surface, fontData) {
    // Create Typeface from the buffer
    using typeface = disposable(CK.Typeface.MakeFreeTypeFaceFromData(fontData));
    surface.draw((canvas) => {
        canvas.clear(CK.Color(240, 240, 240, 1.0));
        using paint = disposable(new CK.Paint());
        paint.setColor(CK.BLACK);
        paint.setAntiAlias(true);
        // Create font using our custom typeface
        using customFont = disposable(new CK.Font(typeface, 40));
        canvas.drawText("Custom Font via WebGPU", 50, 100, paint, customFont);
        // Demonstration of font variations/styling
        using smallFont = disposable(new CK.Font(typeface, 20));
        canvas.drawText("Sub-pixel rendered with Skia Graphite", 50, 150, paint, smallFont);
    });
}
runCustomFontDemo();
