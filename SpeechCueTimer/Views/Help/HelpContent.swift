//
//  HelpContent.swift
//  SpeechCueTimer
//
//  The words of the in-app user guide. Kept apart from the layout in HelpView so
//  the copy is easy to edit. Text supports **bold** (Markdown). Steps that differ
//  between skins are worded for the skin the operator is using.
//

import SwiftUI

struct HelpTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color
    var iconForeground: Color = .white
    let sections: [HelpSection]
}

struct HelpSection {
    var heading: String? = nil
    let items: [HelpItem]
}

enum HelpItem {
    case paragraph(String)
    case steps([String])
    /// A card of rows: control name (or question) with an explanation underneath.
    case rows([HelpRow])
    case legend([HelpSwatch])
    case tip(String)
}

struct HelpRow {
    var systemImage: String? = nil
    let title: String
    let detail: String
}

struct HelpSwatch {
    let color: Color
    let title: String
    let detail: String
}

enum HelpContent {
    static func topics(for skin: AppSkin) -> [HelpTopic] {
        let isGlass = skin == .glassConsole
        let sendButton = isGlass ? "**Send to display**" : "**Send**"
        let setTimeHow = isGlass
            ? "Tap the **hr : min : sec** boxes under **Set time** in the right-hand panel, then spin the wheels."
            : "Tap the countdown in the middle of the ring, the **Custom** chip, or **Timer settings › Set time**, then spin the wheels."
        let statusWhere = isGlass
            ? "The status at the top of the screen says **Display connected** when the speaker display is live."
            : "The top of the right-hand panel says **Speaker display** with a green dot when the speaker display is live."

        return [
            HelpTopic(
                id: "quick-start",
                title: "Quick start",
                summary: "Run your first countdown in four steps.",
                systemImage: "play.fill",
                tint: SkinColor.green,
                iconForeground: SkinColor.onGreen,
                sections: [
                    HelpSection(items: [
                        .steps([
                            "Connect your iPad to the TV, monitor or projector the speaker will see. \(statusWhere)",
                            "Set the length of the talk. \(setTimeHow)",
                            "Tap **Start**. The countdown appears on the speaker display.",
                            "To cue the speaker, tap the message box, type your message and tap \(sendButton).",
                        ]),
                        .tip("Starting the timer clears any message on the speaker display, so send messages after you press **Start**."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "speaker-display",
                title: "The speaker display",
                summary: "What the speaker sees and what the colours mean.",
                systemImage: "display",
                tint: SkinColor.actionBlue,
                sections: [
                    HelpSection(items: [
                        .paragraph(isGlass
                            ? "The speaker display shows the countdown, a progress bar and any message you send. The large preview on your iPad always matches it exactly, animations included."
                            : "The speaker display shows the countdown inside a progress ring, plus any message you send. The preview in the right-hand panel always matches it exactly, animations included."),
                    ]),
                    HelpSection(heading: "Colours", items: [
                        .legend([
                            HelpSwatch(color: SkinColor.green, title: "White digits, green progress", detail: "The timer is running and there's plenty of time left."),
                            HelpSwatch(color: SkinColor.yellow, title: "Yellow", detail: "Wrap-up time: the time left has reached your **Warn at** setting."),
                            HelpSwatch(color: SkinColor.red, title: "Red", detail: "Time is up. The timer keeps counting past zero with a minus sign, for example −00:35, so you can see how far over the talk has run."),
                        ]),
                    ]),
                    HelpSection(heading: "Text size", items: [
                        .rows([
                            HelpRow(
                                systemImage: "textformat.size",
                                title: "A  100%  A",
                                detail: (isGlass ? "At the top of the screen. " : "At the top of the right-hand panel. ")
                                    + "Makes the timer and message on the speaker display smaller or larger, from 50% to 200%. The setting is remembered."
                            ),
                        ]),
                    ]),
                    HelpSection(heading: "Connecting", items: [
                        .paragraph("When nothing is connected, the status reads **No display**. Check the cable or screen mirroring; the app picks up the screen automatically as soon as it connects."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "running",
                title: "Running the timer",
                summary: "Start, pause, adjust and repeat.",
                systemImage: "timer",
                tint: SkinColor.orange,
                iconForeground: SkinColor.onOrange,
                sections: [
                    HelpSection(items: [
                        .rows([
                            HelpRow(systemImage: "playpause.fill", title: "Start / Pause", detail: "One button. It starts the countdown, and pauses it while it's running. Tap **Start** again to carry on from where you paused."),
                            HelpRow(systemImage: "plusminus", title: "−10 / +10", detail: "Removes or adds 10 seconds. Works while the timer is running."),
                            HelpRow(systemImage: "arrow.counterclockwise", title: "Clear", detail: "Sets the timer back to 00:00."),
                            HelpRow(systemImage: "repeat", title: "Repeat", detail: "Puts back the time that was on the clock when you last pressed **Start**, ready for the next speaker."),
                        ]),
                    ]),
                    HelpSection(heading: "Setting the time", items: [
                        .paragraph("\(setTimeHow) Changes apply straight away."),
                        .paragraph("Setting the time is locked while the timer runs, so pause first."),
                    ]),
                    HelpSection(heading: "Progress", items: [
                        .paragraph(isGlass
                            ? "The bar under the preview fills as time passes. The small yellow mark shows where the wrap-up warning will start."
                            : "The ring fills clockwise as time passes. The yellow dot on the ring shows where the wrap-up warning will start."),
                        .tip("The timer keeps counting accurately if you switch to another app."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "quick-times",
                title: "Quick times",
                summary: "Save up to four talk lengths you use often.",
                systemImage: "clock.arrow.circlepath",
                tint: SkinColor.lightBlue,
                iconForeground: SkinColor.background,
                sections: [
                    HelpSection(items: [
                        .paragraph(isGlass
                            ? "The four **Quick times** slots sit along the bottom of the screen."
                            : "The four quick-time chips sit under the ring, next to **Custom**."),
                    ]),
                    HelpSection(heading: "Save a quick time", items: [
                        .steps([
                            "Set the time you want to keep.",
                            "Touch and hold one of the four slots.",
                            "Choose **Save … here**. The menu shows the time it will save.",
                        ]),
                    ]),
                    HelpSection(heading: "Use a quick time", items: [
                        .paragraph("Tap a saved quick time to load it. The slot that matches the time on the clock is highlighted in blue. Quick times can't be loaded or saved while the timer runs."),
                        .tip("Quick times and saved messages are cleared when the app is fully closed. Your warning, pulse, text size and skin settings are remembered."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "messages",
                title: "Messages",
                summary: "Send a note to the speaker's screen.",
                systemImage: "text.bubble.fill",
                tint: SkinColor.actionBlue,
                sections: [
                    HelpSection(heading: "Send a message", items: [
                        .steps([
                            "Tap the message box. The on-screen keyboard opens.",
                            "Type your message. **Return** starts a new line; up to four lines fit on the speaker display.",
                            "Tap \(sendButton).",
                        ]),
                    ]),
                    HelpSection(heading: "Message controls", items: [
                        .rows([
                            HelpRow(
                                systemImage: "eye.slash",
                                title: isGlass ? "Hide" : "Hide message",
                                detail: (isGlass ? "On the blue **On display** bar. " : "On the preview, while a message is showing. ")
                                    + "Takes the message off the speaker display but keeps what you typed."
                            ),
                            HelpRow(
                                systemImage: "xmark",
                                title: "Clear",
                                detail: (isGlass ? "" : "The **×** button. ")
                                    + "Erases what you typed and removes the message from the speaker display."
                            ),
                            HelpRow(systemImage: "bolt.fill", title: "Zap", detail: "Shakes the message on the speaker display to catch the speaker's eye. Only available while a message is showing."),
                        ]),
                    ]),
                    HelpSection(heading: "The keyboard", items: [
                        .paragraph("Word suggestions appear above the keys as you type. The smiley key opens emoji. Tap **Done**, or anywhere outside the keyboard, to close it."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "saved-messages",
                title: "Saved messages",
                summary: "Keep four messages ready to go.",
                systemImage: "tray.full.fill",
                tint: SkinColor.purple,
                iconForeground: SkinColor.background,
                sections: [
                    HelpSection(items: [
                        .paragraph("There are four saved-message slots. The first one starts with **Times up!**"),
                    ]),
                    HelpSection(heading: "Use a saved message", items: [
                        .paragraph(isGlass
                            ? "Tap a saved message to load it into the message box. Edit it if you like, then tap **Send to display**. To put it up straight away instead, touch and hold it and choose **Send to display**."
                            : "Tap the arrow next to a saved message to put it on the speaker display straight away. Whatever you're typing is kept. Tap the message itself to load it into the message box instead. The message that's showing is tagged **On display**."),
                    ]),
                    HelpSection(heading: "Save a message", items: [
                        .steps([
                            "Type the message in the message box.",
                            "Tap an empty slot (it says **Save draft here**), or touch and hold any slot and choose **Save current message here** to replace it.",
                        ]),
                    ]),
                ]
            ),

            HelpTopic(
                id: "warning",
                title: "Wrap-up warning",
                summary: "Choose when the timer turns yellow.",
                systemImage: "exclamationmark.triangle.fill",
                tint: SkinColor.yellow,
                iconForeground: SkinColor.onYellow,
                sections: [
                    HelpSection(items: [
                        .paragraph(isGlass
                            ? "The **Warning** section is in the right-hand panel."
                            : "Open **Timer settings** in the right-hand panel."),
                        .rows([
                            HelpRow(systemImage: "exclamationmark.triangle.fill", title: "Warn at", detail: "When this much time is left, the timer and progress turn yellow. Use **−** and **+** to change it in 30-second steps, from 0:10 up to 10:00. The default is 1:00."),
                            HelpRow(systemImage: "waveform", title: "Pulse during warning", detail: "Makes the countdown zoom gently in and out while it's yellow, so the speaker notices. Turn it off for a calmer display."),
                        ]),
                        .tip("Both settings are remembered the next time you open the app."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "skins",
                title: "Skins",
                summary: "Switch between Glass Console and Stage Ring.",
                systemImage: "paintpalette.fill",
                tint: SkinColor.red,
                sections: [
                    HelpSection(items: [
                        .paragraph("The app has two layouts. Both do the same things, so pick the one that suits you."),
                        .rows([
                            HelpRow(systemImage: "rectangle.inset.filled", title: AppSkin.glassConsole.title, detail: "A large preview of the speaker display, the controls in a floating bar underneath, and a side panel for messages and settings."),
                            HelpRow(systemImage: "circle.dashed", title: AppSkin.stageRing.title, detail: "A big progress ring with the controls underneath, and a side panel with a live preview, messages and timer settings."),
                        ]),
                    ]),
                    HelpSection(heading: "Switch skins", items: [
                        .steps([
                            "Tap the gear button at the top of the screen.",
                            "Choose a skin.",
                        ]),
                        .paragraph("The operator screen and the speaker display both change straight away. Your timer and messages carry on."),
                    ]),
                ]
            ),

            HelpTopic(
                id: "troubleshooting",
                title: "Troubleshooting",
                summary: "Fixes for common problems.",
                systemImage: "wrench.and.screwdriver.fill",
                tint: Color(white: 0.55),
                sections: [
                    HelpSection(items: [
                        .rows([
                            HelpRow(title: "Start is greyed out", detail: "There's no time on the clock. Set a time or tap a quick time first."),
                            HelpRow(title: "I can't change the time", detail: "Setting the time and quick times are locked while the timer runs. Pause first."),
                            HelpRow(title: "The speaker display is blank, or the app says No display", detail: "Check the cable or screen mirroring. The app finds the screen automatically when it connects."),
                            HelpRow(title: "My message disappeared", detail: "Starting the timer clears the message from the speaker display. Send it again after you press **Start**."),
                            HelpRow(title: "Zap does nothing", detail: "Zap only works while a message is on the speaker display."),
                            HelpRow(title: "The screen turned off during a talk", detail: "The iPad locked itself. Before an event, open the iPad's **Settings › Display & Brightness › Auto-Lock** and choose **Never**."),
                        ]),
                    ]),
                ]
            ),
        ]
    }
}
