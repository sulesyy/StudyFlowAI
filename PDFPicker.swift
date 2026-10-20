//
//  PDFPicker.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFPicker: UIViewControllerRepresentable {

    @Binding var selectedURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf]
        )

        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) { }

    class Coordinator: NSObject, UIDocumentPickerDelegate {

        let parent: PDFPicker

        init(_ parent: PDFPicker) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {

            parent.selectedURL = urls.first

        }
    }
}
