package main

import (
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/container"
    "fyne.io/fyne/v2/widget"
)

func main() {
    myApp := app.New()
    w := myApp.NewWindow("Fyne Sidebar Example")

    // Create sidebar items
    sidebar := container.NewVBox(
        widget.NewButton("Home", func() {}),
        widget.NewButton("Settings", func() {}),
        widget.NewButton("About", func() {}),
    )

    // Main content area
    content := widget.NewLabel("Main Content Area")

    // Use Border layout: left sidebar
    layout := container.NewBorder(nil, nil, sidebar, nil, content)

    w.SetContent(layout)
//  w.Resize(fyne.NewSize(400, 300))
    w.ShowAndRun()
}
