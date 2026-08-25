import Foundation
import XCTest
@testable import EchoPet

final class EchoAPIClientTests: XCTestCase {
    func testEndpointPathsMatchSharedContract() {
        let petID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let memoryID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let timelineID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let capsuleID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

        XCTAssertEqual(EchoAPIEndpoint.login.method, .post)
        XCTAssertEqual(EchoAPIEndpoint.login.path, "/v1/auth/login")
        XCTAssertEqual(EchoAPIEndpoint.pets.method, .get)
        XCTAssertEqual(EchoAPIEndpoint.pets.path, "/v1/pets")
        XCTAssertEqual(EchoAPIEndpoint.createPet.method, .post)
        XCTAssertEqual(EchoAPIEndpoint.updatePet(petID).method, .put)
        XCTAssertEqual(EchoAPIEndpoint.deletePet(petID).method, .delete)
        XCTAssertEqual(EchoAPIEndpoint.petMemories(petID).path, "/v1/pets/\(petID.uuidString)/memories")
        XCTAssertEqual(EchoAPIEndpoint.memory(memoryID).path, "/v1/memories/\(memoryID.uuidString)")
        XCTAssertEqual(EchoAPIEndpoint.memoryMedia(memoryID).path, "/v1/memories/\(memoryID.uuidString)/media")
        XCTAssertEqual(EchoAPIEndpoint.lifePrint(petID).path, "/v1/pets/\(petID.uuidString)/lifeprint")
        XCTAssertEqual(EchoAPIEndpoint.generateLifePrint(petID).path, "/v1/pets/\(petID.uuidString)/lifeprint/generate")
        XCTAssertEqual(EchoAPIEndpoint.timeline(petID).path, "/v1/pets/\(petID.uuidString)/timeline")
        XCTAssertEqual(EchoAPIEndpoint.timelineEvent(timelineID).path, "/v1/timeline/\(timelineID.uuidString)")
        XCTAssertEqual(EchoAPIEndpoint.capsules(petID).path, "/v1/pets/\(petID.uuidString)/capsules")
        XCTAssertEqual(EchoAPIEndpoint.generateCapsule(petID).path, "/v1/pets/\(petID.uuidString)/capsules/generate")
        XCTAssertEqual(EchoAPIEndpoint.capsule(capsuleID).path, "/v1/capsules/\(capsuleID.uuidString)")
        XCTAssertEqual(EchoAPIEndpoint.companionMessages(petID).path, "/v1/pets/\(petID.uuidString)/companion/messages")
        XCTAssertEqual(EchoAPIEndpoint.companionChat(petID).path, "/v1/pets/\(petID.uuidString)/companion/chat")
        XCTAssertEqual(EchoAPIEndpoint.exportPetData(petID).path, "/v1/pets/\(petID.uuidString)/export")
        XCTAssertEqual(EchoAPIEndpoint.deleteMe.method, .delete)
        XCTAssertEqual(EchoAPIEndpoint.contractExamples().count, 24)
    }

    func testStubBuildsAuthorizedJSONRequest() throws {
        let petID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let memoryID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let client = EchoAPIStubClient(
            baseURL: URL(string: "https://api.example.com")!,
            bearerToken: "test-token"
        )
        let pet = PetProfile(
            id: petID,
            name: "豆包",
            species: "猫",
            breed: "狸花猫",
            age: "4 岁",
            relationshipLabel: "主人",
            personality: "亲人、安静、好奇",
            mbti: "温柔观察型",
            favoriteThings: ["窗边晒太阳"],
            habits: ["听到钥匙声就跑来"]
        )
        let context = try XCTUnwrap(
            AIContextBuilder().build(
                pet: pet,
                lifePrint: LifePrint(summary: "豆包喜欢安静陪伴。", updatedAt: Date(timeIntervalSince1970: 1)),
                timeline: [
                    TimelineEvent(
                        petID: petID,
                        memoryID: memoryID,
                        date: Date(timeIntervalSince1970: 1),
                        title: "第一次回家",
                        story: "豆包慢慢靠近你的手。",
                        imageSystemName: "house.fill"
                    )
                ],
                dailyTasks: [
                    DailyCareTask(petID: petID, title: "换一碗新鲜水", template: .feeding)
                ],
                messages: [],
                settings: .default
            )
        )
        let body = CompanionChatRequest(
            message: "我想它了",
            relationship: RelationshipContext(userRole: "主人", petRole: "宠物"),
            context: context
        )

        let request = try client.makeURLRequest(for: .companionChat(petID), body: body)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.example.com/v1/pets/\(petID.uuidString)/companion/chat"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(request.httpBody)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedBody = try decoder.decode(CompanionChatRequest.self, from: try XCTUnwrap(request.httpBody))

        XCTAssertEqual(decodedBody.context?.pet.name, "豆包")
        XCTAssertEqual(decodedBody.context?.lifePrint?.summary, "豆包喜欢安静陪伴。")
        XCTAssertEqual(decodedBody.context?.timelineMemories.first?.memoryID, memoryID)
        XCTAssertEqual(decodedBody.context?.dailyTasks.first?.title, "换一碗新鲜水")
        XCTAssertEqual(decodedBody.context?.tone, .gentleCompanion)
    }

    func testHTTPClientPostsCompanionChatAndDecodesResponse() async throws {
        let petID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let responseBody = """
        {
          "messageId": "reply-1",
          "reply": "我会轻轻陪着你。\\n（本消息由 AI 基于宠物记忆生成）",
          "isAiGenerated": true,
          "sourceMemoryIds": ["00000000-0000-0000-0000-000000000002"],
          "modelVersion": "deepseek-v4-flash-stub-v1"
        }
        """
        let session = MockEchoURLSession(
            data: Data(responseBody.utf8),
            response: HTTPURLResponse(
                url: EchoBackendConfiguration.localStubBaseURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        let client = EchoAPIHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8000")!,
            urlSession: session
        )

        let response = try await client.companionChat(
            petID: petID,
            request: CompanionChatRequest(
                message: "我有点想豆包",
                relationship: RelationshipContext(userRole: "主人", petRole: "猫")
            )
        )

        XCTAssertEqual(response.messageID, "reply-1")
        XCTAssertEqual(response.modelVersion, "deepseek-v4-flash-stub-v1")
        XCTAssertTrue(response.isAIGenerated)
        XCTAssertEqual(response.sourceMemoryIDs, ["00000000-0000-0000-0000-000000000002"])
        XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(
            session.lastRequest?.url?.absoluteString,
            "http://127.0.0.1:8000/v1/pets/\(petID.uuidString)/companion/chat"
        )
    }

    func testSupabaseCloudSyncSignsInAndUpsertsState() async throws {
        let petID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let projectURL = URL(string: "https://example.supabase.co")!
        let authResponse = """
        {
          "access_token": "anon-access-token",
          "refresh_token": "anon-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000099" }
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(authResponse, statusCode: 200, url: projectURL),
            .empty(statusCode: 201, url: projectURL),
            .empty(statusCode: 201, url: projectURL)
        ])
        let suiteName = "EchoSupabaseClientTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )
        let cloudSync = EchoCloudSyncService(authService: authService, api: api)
        let pet = PetProfile(
            id: petID,
            name: "豆包",
            species: "猫",
            breed: "狸花猫",
            age: "4 岁",
            relationshipLabel: "家人",
            personality: "亲人、安静、好奇",
            mbti: "温柔观察型",
            favoriteThings: ["窗边晒太阳"],
            habits: ["听到钥匙声就跑来"]
        )
        let appState = EchoAppState(
            accountSession: nil,
            pet: pet,
            dailyTasks: [
                DailyCareTask(
                    petID: petID,
                    title: "换一碗新鲜水",
                    dueAt: Date(timeIntervalSince1970: 3600),
                    date: Date(timeIntervalSince1970: 0),
                    template: .feeding
                ),
                DailyCareTask(
                    petID: petID,
                    title: "拍一张今日照片",
                    date: Date(timeIntervalSince1970: 0),
                    template: .photo,
                    isCompleted: true
                )
            ],
            timeline: [],
            messages: [],
            capsules: [],
            lifePrint: nil
        )

        try await cloudSync.syncState(appState, allowAnonymous: true)

        XCTAssertEqual(session.requests.map { $0.url?.absoluteString }, [
            "https://example.supabase.co/auth/v1/signup",
            "https://example.supabase.co/rest/v1/pets?on_conflict=id",
            "https://example.supabase.co/rest/v1/daily_tasks?on_conflict=id"
        ])
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "apikey"), "test-publishable-key")
        XCTAssertEqual(session.requests[1].value(forHTTPHeaderField: "Authorization"), "Bearer anon-access-token")

        let dailyTaskBody = try XCTUnwrap(session.requests[2].httpBody)
        let dailyTasks = try XCTUnwrap(JSONSerialization.jsonObject(with: dailyTaskBody) as? [[String: Any]])
        XCTAssertEqual(dailyTasks.count, 2)
        XCTAssertNotNil(dailyTasks[0]["due_at"])
        XCTAssertTrue(dailyTasks[1].keys.contains("due_at"))
    }

    func testSupabaseCompanionClientUsesSessionAndCallsEdgeFunction() async throws {
        let petID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let projectURL = URL(string: "https://example.supabase.co")!
        let authResponse = """
        {
          "access_token": "anon-access-token",
          "refresh_token": "anon-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000099" }
        }
        """
        let functionResponse = """
        {
          "messageId": "supabase-reply-1",
          "reply": "我已经从 Supabase 读到豆包的记忆。\\n（本消息由 AI 基于宠物记忆生成）",
          "isAiGenerated": true,
          "sourceMemoryIds": [],
          "modelVersion": "deepseek-v4-flash-deepseek-v1"
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(authResponse, statusCode: 200, url: projectURL),
            .json(functionResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseCompanionClientTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )
        let client = EchoSupabaseCompanionClient(authService: authService, api: api)

        let response = try await client.companionChat(
            petID: petID,
            request: CompanionChatRequest(
                message: "我有点想豆包",
                relationship: RelationshipContext(userRole: "主人", petRole: "猫")
            )
        )

        XCTAssertEqual(response.messageID, "supabase-reply-1")
        XCTAssertEqual(response.modelVersion, "deepseek-v4-flash-deepseek-v1")
        XCTAssertEqual(session.requests.map { $0.url?.absoluteString }, [
            "https://example.supabase.co/auth/v1/signup",
            "https://example.supabase.co/functions/v1/companion-chat"
        ])
        XCTAssertEqual(session.requests[1].value(forHTTPHeaderField: "Authorization"), "Bearer anon-access-token")

        let functionBody = try XCTUnwrap(session.requests[1].httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: functionBody) as? [String: Any])
        XCTAssertEqual(json["petId"] as? String, petID.uuidString)
        XCTAssertEqual(json["message"] as? String, "我有点想豆包")
    }

    func testSupabaseAuthServicePostsEmailPasswordSignIn() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let emailAuthResponse = """
        {
          "access_token": "email-access-token",
          "refresh_token": "email-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000077" }
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(emailAuthResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseEmailSignInTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        let accountSession = try await authService.signInWithEmail(
            EmailPasswordAuthRequest(
                email: "person@example.com",
                password: "password123"
            )
        ).accountSession

        XCTAssertEqual(accountSession.provider, .email)
        XCTAssertEqual(accountSession.displayName, "person@example.com")
        XCTAssertEqual(accountSession.email, "person@example.com")
        XCTAssertEqual(session.requests.first?.url?.absoluteString, "https://example.supabase.co/auth/v1/token?grant_type=password")
        let body = try XCTUnwrap(session.requests.first?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["email"] as? String, "person@example.com")
        XCTAssertEqual(json["password"] as? String, "password123")
    }

    func testSupabaseAuthServicePostsEmailPasswordSignUp() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let emailAuthResponse = """
        {
          "access_token": "email-access-token",
          "refresh_token": "email-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000076" }
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(emailAuthResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseEmailSignUpTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        let accountSession = try await authService.signUpWithEmail(
            EmailPasswordAuthRequest(
                email: "new-person@example.com",
                password: "password123"
            )
        ).accountSession

        XCTAssertEqual(accountSession.provider, .email)
        XCTAssertEqual(accountSession.displayName, "new-person@example.com")
        XCTAssertEqual(accountSession.email, "new-person@example.com")
        XCTAssertEqual(session.requests.first?.url?.absoluteString, "https://example.supabase.co/auth/v1/signup")
        let body = try XCTUnwrap(session.requests.first?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["email"] as? String, "new-person@example.com")
        XCTAssertEqual(json["password"] as? String, "password123")
    }

    func testSupabaseAuthServiceClearsStoredSessionBeforeEmailSignUpFailure() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let emailAuthResponse = """
        {
          "access_token": "old-email-access-token",
          "refresh_token": "old-email-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000075" }
        }
        """
        let signUpFailure = """
        { "msg": "signup failed" }
        """
        let session = QueueEchoURLSession(responses: [
            .json(emailAuthResponse, statusCode: 200, url: projectURL),
            .json(signUpFailure, statusCode: 400, url: projectURL)
        ])
        let suiteName = "EchoSupabaseEmailSignUpClearsStaleSessionTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        _ = try await authService.signInWithEmail(
            EmailPasswordAuthRequest(
                email: "deleted-person@example.com",
                password: "password123"
            )
        )
        XCTAssertNotNil(authService.storedSession())

        do {
            _ = try await authService.signUpWithEmail(
                EmailPasswordAuthRequest(
                    email: "deleted-person@example.com",
                    password: "password123"
                )
            )
            XCTFail("Expected sign-up failure")
        } catch EchoAPIClientError.httpStatus(let statusCode) {
            XCTAssertEqual(statusCode, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(authService.storedSession())
        XCTAssertEqual(session.requests.map { $0.url?.absoluteString }, [
            "https://example.supabase.co/auth/v1/token?grant_type=password",
            "https://example.supabase.co/auth/v1/signup"
        ])
    }

    func testSupabaseAuthServiceTreatsSignUpWithoutSessionAsEmailConfirmationRequired() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let confirmationResponse = """
        {
          "user": { "id": "00000000-0000-0000-0000-000000000077" }
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(confirmationResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseEmailConfirmationTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        do {
            _ = try await authService.signUpWithEmail(
                EmailPasswordAuthRequest(
                    email: "verify-me@example.com",
                    password: "password123"
                )
            )
            XCTFail("Expected email confirmation requirement")
        } catch EchoSupabaseAuthError.emailConfirmationRequired {
            XCTAssertNil(userDefaults.data(forKey: "test-session"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSupabaseAuthServiceTreatsTopLevelSignUpUserAsEmailConfirmationRequired() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let confirmationResponse = """
        {
          "id": "00000000-0000-0000-0000-000000000078",
          "email": "verify-top-level@example.com"
        }
        """
        let session = QueueEchoURLSession(responses: [
            .json(confirmationResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseTopLevelEmailConfirmationTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        do {
            _ = try await authService.signUpWithEmail(
                EmailPasswordAuthRequest(
                    email: "verify-top-level@example.com",
                    password: "password123"
                )
            )
            XCTFail("Expected email confirmation requirement")
        } catch EchoSupabaseAuthError.emailConfirmationRequired {
            XCTAssertNil(userDefaults.data(forKey: "test-session"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSupabaseAuthServicePostsPasswordRecovery() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let session = QueueEchoURLSession(responses: [
            .json("{}", statusCode: 200, url: projectURL)
        ])
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(api: api)

        try await authService.resetPassword(forEmail: "echo@example.com")

        XCTAssertEqual(session.requests.count, 1)
        XCTAssertEqual(session.requests.first?.url?.absoluteString, "https://example.supabase.co/auth/v1/recover")
        XCTAssertEqual(session.requests.first?.httpMethod, "POST")
        let body = try XCTUnwrap(session.requests.first?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["email"] as? String, "echo@example.com")
    }

    func testSupabaseAuthServiceDeletesAccountThroughEdgeFunction() async throws {
        let projectURL = URL(string: "https://example.supabase.co")!
        let emailAuthResponse = """
        {
          "access_token": "email-access-token",
          "refresh_token": "email-refresh-token",
          "expires_in": 3600,
          "user": { "id": "00000000-0000-0000-0000-000000000088" }
        }
        """
        let deleteResponse = """
        { "deleted": true }
        """
        let session = QueueEchoURLSession(responses: [
            .json(emailAuthResponse, statusCode: 200, url: projectURL),
            .json(deleteResponse, statusCode: 200, url: projectURL)
        ])
        let suiteName = "EchoSupabaseDeleteAccountTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let api = EchoSupabaseAPI(
            projectURL: projectURL,
            publishableKey: "test-publishable-key",
            urlSession: session
        )
        let authService = EchoSupabaseAuthService(
            api: api,
            userDefaults: userDefaults,
            sessionStorageKey: "test-session"
        )

        _ = try await authService.signInWithEmail(
            EmailPasswordAuthRequest(
                email: "echo@example.com",
                password: "password123"
            )
        )
        try await authService.deleteAccount()

        XCTAssertEqual(session.requests.count, 2)
        XCTAssertEqual(session.requests.last?.url?.absoluteString, "https://example.supabase.co/functions/v1/delete-account")
        XCTAssertEqual(session.requests.last?.httpMethod, "POST")
        XCTAssertEqual(session.requests.last?.value(forHTTPHeaderField: "Authorization"), "Bearer email-access-token")
        XCTAssertNil(authService.storedSession())
    }

    func testStubThrowsBackendNotConnectedForTypedCalls() async {
        let client = EchoAPIStubClient()

        do {
            _ = try await client.listPets()
            XCTFail("Expected backendNotConnected error.")
        } catch EchoAPIClientError.backendNotConnected(let endpoint) {
            XCTAssertEqual(endpoint, .pets)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MockEchoURLSession: EchoURLSession {
    let data: Data
    let response: URLResponse
    private(set) var lastRequest: URLRequest?

    init(data: Data, response: URLResponse) {
        self.data = data
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        return (data, response)
    }
}

private final class QueueEchoURLSession: EchoURLSession {
    struct Response {
        var data: Data
        var statusCode: Int
        var url: URL

        static func json(_ value: String, statusCode: Int, url: URL) -> Response {
            Response(data: Data(value.utf8), statusCode: statusCode, url: url)
        }

        static func empty(statusCode: Int, url: URL) -> Response {
            Response(data: Data(), statusCode: statusCode, url: url)
        }
    }

    private var responses: [Response]
    private(set) var requests: [URLRequest] = []

    init(responses: [Response]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let response = responses.removeFirst()
        let httpResponse = HTTPURLResponse(
            url: response.url,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response.data, httpResponse)
    }
}
