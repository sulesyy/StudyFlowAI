import XCTest

final class StudyFlowAIUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCourseProgressPlanStatisticsAndAITabs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStudyFlowForUITest"]
        app.launch()

        let todayTab = app.tabBars.buttons["Bugün"]
        let coursesTab = app.tabBars.buttons["Dersler"]
        let aiTab = app.tabBars.buttons["AI"]
        let statisticsTab = app.tabBars.buttons["İstatistik"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 10))
        XCTAssertTrue(coursesTab.exists)
        XCTAssertTrue(aiTab.exists)
        XCTAssertTrue(statisticsTab.exists)

        coursesTab.tap()
        let addCourseButton = app.buttons["Yeni ders ekle"]
        XCTAssertTrue(addCourseButton.waitForExistence(timeout: 5))
        addCourseButton.tap()

        let nameField = app.textFields["courseNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        let saveButton = app.buttons["saveCourseButton"]
        XCTAssertFalse(saveButton.isEnabled, "Kaydet, boş formda kapalı olmalı.")
        let courseName = "UI Test Dersi"
        nameField.tap()
        nameField.typeText(courseName)
        XCTAssertFalse(saveButton.isEnabled, "Konu eklenmeden kaydet kapalı olmalı.")

        let topicsField = app.textViews["courseTopicsField"]
        XCTAssertTrue(topicsField.exists)
        topicsField.tap()
        topicsField.typeText("Fotosentez\nHücre")

        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        // Respond to the system notification prompt if the simulator presents it.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permissionAlert = springboard.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 3) {
            let allowPredicate = NSPredicate(
                format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
                "allow",
                "izin"
            )
            let allowButton = permissionAlert.buttons.matching(allowPredicate).firstMatch
            if allowButton.exists {
                allowButton.tap()
            }
        }

        let reminderFailure = app.alerts["Hatırlatıcı kurulamadı"]
        if reminderFailure.waitForExistence(timeout: 3) {
            reminderFailure.buttons["Tamam"].tap()
        }

        let courseCard = app.descendants(matching: .any)
            .matching(identifier: "courseCard-\(courseName)").firstMatch
        XCTAssertTrue(courseCard.waitForExistence(timeout: 10))
        courseCard.tap()

        XCTAssertTrue(app.staticTexts["0 / 2 konu tamamlandı"].waitForExistence(timeout: 5))
        let firstTopic = app.buttons["topicCompletion-Fotosentez"]
        XCTAssertTrue(firstTopic.exists)
        firstTopic.tap()
        XCTAssertTrue(app.staticTexts["1 / 2 konu tamamlandı"].waitForExistence(timeout: 5))

        // Unchecking a topic must not increase the study streak.
        firstTopic.tap()
        XCTAssertTrue(app.staticTexts["0 / 2 konu tamamlandı"].waitForExistence(timeout: 5))
        todayTab.tap()
        XCTAssertTrue(app.staticTexts["1 gün"].waitForExistence(timeout: 5))

        coursesTab.tap()
        let planLink = app.buttons["studyPlanLink"]
        XCTAssertTrue(planLink.waitForExistence(timeout: 5))
        planLink.tap()
        XCTAssertTrue(app.staticTexts["Fotosentez"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hücre"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        statisticsTab.tap()
        XCTAssertTrue(app.staticTexts["Genel Durum"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Genel İlerleme"].exists)
        XCTAssertTrue(app.staticTexts["%0 tamamlandı"].exists)

        aiTab.tap()
        XCTAssertTrue(app.staticTexts["Neye çalışıyorsun?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Ders konusu"].exists)
        XCTAssertTrue(app.staticTexts["PDF’den çalış"].exists)
        XCTAssertTrue(app.staticTexts["Kaydedilen içerikler"].exists)
        app.staticTexts["PDF’den çalış"].tap()
        XCTAssertTrue(app.navigationBars["PDF AI"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["PDF Seç"].exists)

        coursesTab.tap()
        let courseMenu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "courseMenu-")).firstMatch
        XCTAssertTrue(courseMenu.waitForExistence(timeout: 5))
        courseMenu.tap()
        app.buttons["Sil"].tap()
        XCTAssertTrue(app.staticTexts["Henüz dersin yok"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFocusTimerAndBackupScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetStudyFlowForUITest"]
        app.launch()

        let focusButton = app.buttons["openFocusTimer"]
        XCTAssertTrue(focusButton.waitForExistence(timeout: 10))
        focusButton.tap()
        XCTAssertTrue(app.navigationBars["Odak sayacı"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["25:00"].exists)
        app.buttons["focusTimerStartPause"].tap()
        XCTAssertTrue(app.buttons["Duraklat"].waitForExistence(timeout: 3))
        app.buttons["Duraklat"].tap()
        app.buttons["Kapat"].tap()

        let backupButton = app.buttons["openBackup"]
        XCTAssertTrue(backupButton.waitForExistence(timeout: 5))
        backupButton.tap()
        XCTAssertTrue(app.navigationBars["Yedekleme"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["exportStudyFlowBackup"].exists)
        XCTAssertTrue(app.buttons["importStudyFlowBackup"].exists)
    }
}
