//
//  AddCourseView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import SwiftUI

struct AddCourseView: View {

    @ObservedObject var viewModel: StudyPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var courseName = ""
    @State private var examDate = Date()
    @State private var difficulty = 3
    @State private var topicsText = ""
    @State private var isSaving = false
    @State private var showNotificationAlert = false

    private var cleanedCourseName: String {
        courseName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var topicList: [StudyTopic] {
        topicsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { StudyTopic(title: $0) }
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Ders Bilgileri") {

                    TextField("Ders Adı", text: $courseName)
                        .accessibilityIdentifier("courseNameField")

                    DatePicker(
                        "Sınav Tarihi",
                        selection: $examDate,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: .date
                    )

                    Stepper(
                        "Zorluk: \(difficulty)",
                        value: $difficulty,
                        in: 1...5
                    )

                }

                Section("Konular") {

                    TextEditor(text: $topicsText)
                        .frame(height: 120)
                        .accessibilityIdentifier("courseTopicsField")

                    Text("Her konuyu yeni satıra yaz.")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("En az bir konu ekle; her satıra bir konu yaz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }


                Section {

                    Button {
                        Task { await saveCourse() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Kaydet")
                        }
                    }
                    .disabled(cleanedCourseName.isEmpty || topicList.isEmpty || isSaving)
                    .accessibilityIdentifier("saveCourseButton")
                }

            }
            .navigationTitle("Yeni Ders")
            .alert("Hatırlatıcı kurulamadı", isPresented: $showNotificationAlert) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Dersin kaydedildi. Çalışma hatırlatıcısı kurulamadı. Ayarlar’dan StudyFlow AI bildirimlerine izin verip tekrar deneyebilirsin.")
            }

        }

    }

    @MainActor
    private func saveCourse() async {
        guard !cleanedCourseName.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let tasks = StudyPlanGenerator.generateTasks(topics: topicList, examDate: examDate)
        let course = Course(
            name: cleanedCourseName,
            examDate: examDate,
            difficulty: difficulty,
            topics: topicList,
            studyTasks: tasks
        )
        viewModel.addCourse(course)

        guard let firstTask = tasks.first else {
            dismiss()
            return
        }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: firstTask.date)
        var reminderDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? firstTask.date
        if reminderDate <= Date() {
            reminderDate = calendar.date(byAdding: .day, value: 1, to: reminderDate) ?? Date().addingTimeInterval(86_400)
        }

        let scheduled = await NotificationManager.shared.scheduleNotification(
            title: "StudyFlow AI çalışma zamanı",
            body: "Bugünkü planında \(course.name) dersi var.",
            date: reminderDate
        )
        if scheduled {
            dismiss()
        } else {
            showNotificationAlert = true
        }
    }
}

#Preview {
    AddCourseView(viewModel: StudyPlannerViewModel())
}
