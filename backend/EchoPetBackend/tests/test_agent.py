import unittest

from app.agent import EN_AI_DISCLOSURE, ZH_AI_DISCLOSURE, build_companion_reply


class CompanionAgentTests(unittest.TestCase):
    def test_reply_uses_pet_lifeprint_timeline_and_daily_task_context(self):
        memory_id = "00000000-0000-0000-0000-000000000002"
        response = build_companion_reply(
            {
                "message": "我有点想豆包",
                "relationship": {
                    "userRole": "主人",
                    "petRole": "猫",
                },
                "context": {
                    "languageCode": "zh_Hans",
                    "tone": "gentleCompanion",
                    "pet": {
                        "petId": "00000000-0000-0000-0000-000000000001",
                        "name": "豆包",
                        "species": "猫",
                        "breed": "狸花猫",
                        "age": "4 岁",
                        "relationshipLabel": "家人",
                        "personality": "亲人、安静、好奇",
                        "mbti": "温柔观察型",
                        "favoriteThings": ["窗边晒太阳"],
                        "habits": ["听到钥匙声就跑来"],
                    },
                    "lifePrint": {
                        "summary": "豆包喜欢安静陪伴。",
                        "updatedAt": "2026-08-09T00:00:00Z",
                        "personalityTraits": ["亲人、安静"],
                        "favoriteThings": ["窗边晒太阳"],
                        "habits": ["等钥匙声"],
                        "sourceMemoryIds": [memory_id],
                        "isAiGenerated": True,
                    },
                    "timelineMemories": [
                        {
                            "timelineId": "00000000-0000-0000-0000-000000000003",
                            "memoryId": memory_id,
                            "date": "2022-04-08T00:00:00Z",
                            "title": "第一次回家",
                            "story": "豆包慢慢靠近你的手。",
                            "mediaAssetCount": 2,
                            "sourceMemoryIds": [memory_id],
                        }
                    ],
                    "dailyTasks": [
                        {
                            "taskId": "00000000-0000-0000-0000-000000000004",
                            "title": "换一碗新鲜水",
                            "template": "feeding",
                            "isCompleted": False,
                        }
                    ],
                    "recentMessages": [],
                    "privacy": {
                        "allowsMemoryContext": True,
                        "usesPetProfile": True,
                        "usesLifePrint": True,
                        "usesTimeline": True,
                        "usesDailyTasks": True,
                        "usesChatHistory": False,
                    },
                },
            },
            pet_id="00000000-0000-0000-0000-000000000001",
        )

        self.assertTrue(response["isAiGenerated"])
        self.assertEqual(response["modelVersion"], "deepseek-v4-flash-stub-v1")
        self.assertIn("豆包", response["reply"])
        self.assertIn("第一次回家", response["reply"])
        self.assertIn("亲人、安静", response["reply"])
        self.assertIn(ZH_AI_DISCLOSURE, response["reply"])
        self.assertEqual(response["sourceMemoryIds"], [memory_id])
        self.assertNotIn("复活", response["reply"])

    def test_reply_respects_disabled_memory_context(self):
        response = build_companion_reply(
            {
                "message": "我有点想它",
                "relationship": {
                    "userRole": "主人",
                    "petRole": "宠物",
                },
                "context": {
                    "languageCode": "zh_Hans",
                    "privacy": {
                        "allowsMemoryContext": False,
                    },
                    "pet": {
                        "name": "豆包",
                    },
                    "timelineMemories": [
                        {
                            "title": "第一次回家",
                            "story": "这条不应该被使用。",
                        }
                    ],
                },
            },
            pet_id="pet-1",
        )

        self.assertIn("允许我使用宠物记忆", response["reply"])
        self.assertNotIn("第一次回家", response["reply"])
        self.assertEqual(response["sourceMemoryIds"], [])

    def test_english_reply_uses_english_disclosure(self):
        response = build_companion_reply(
            {
                "message": "I miss Momo",
                "relationship": {
                    "userRole": "owner",
                    "petRole": "dog",
                },
                "context": {
                    "languageCode": "en",
                    "pet": {
                        "name": "Momo",
                        "personality": "gentle and curious",
                    },
                    "lifePrint": None,
                    "timelineMemories": [
                        {
                            "title": "First Day Home",
                            "story": "Momo chose the soft rug.",
                            "sourceMemoryIds": ["memory-1"],
                        }
                    ],
                    "dailyTasks": [],
                    "recentMessages": [],
                    "privacy": {
                        "allowsMemoryContext": True,
                    },
                },
            },
            pet_id="pet-1",
        )

        self.assertIn("Momo", response["reply"])
        self.assertIn("First Day Home", response["reply"])
        self.assertIn(EN_AI_DISCLOSURE, response["reply"])
        self.assertNotIn(ZH_AI_DISCLOSURE, response["reply"])


if __name__ == "__main__":
    unittest.main()
