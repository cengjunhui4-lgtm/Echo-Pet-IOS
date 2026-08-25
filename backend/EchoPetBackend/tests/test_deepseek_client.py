import unittest

from app.deepseek_client import DeepSeekClient, build_deepseek_messages


class DeepSeekClientTests(unittest.TestCase):
    def test_build_deepseek_messages_includes_safety_rules_and_context(self):
        messages = build_deepseek_messages(
            {
                "message": "我有点想豆包",
                "relationship": {
                    "userRole": "主人",
                    "petRole": "猫",
                },
                "context": {
                    "languageCode": "zh_Hans",
                    "pet": {
                        "name": "豆包",
                        "personality": "亲人、安静",
                    },
                    "timelineMemories": [
                        {
                            "title": "第一次回家",
                            "story": "豆包慢慢靠近你的手。",
                        }
                    ],
                },
            },
            pet_id="pet-1",
        )

        self.assertEqual(messages[0]["role"], "system")
        self.assertIn("不能声称宠物真实复活", messages[0]["content"])
        self.assertIn("不要自行添加结尾 AI 提示", messages[0]["content"])
        self.assertIn("豆包", messages[1]["content"])
        self.assertIn("第一次回家", messages[1]["content"])

    def test_deepseek_client_posts_openai_compatible_payload(self):
        captured = {}

        def fake_transport(payload, headers, timeout_seconds):
            captured["payload"] = payload
            captured["headers"] = headers
            captured["timeout"] = timeout_seconds
            return {
                "choices": [
                    {
                        "message": {
                            "content": "我会轻轻陪着你。"
                        }
                    }
                ]
            }

        client = DeepSeekClient(
            api_key="test-key",
            model="deepseek-v4-flash",
            timeout_seconds=12,
            transport=fake_transport,
        )

        reply = client.chat([
            {"role": "system", "content": "system"},
            {"role": "user", "content": "hello"},
        ])

        self.assertEqual(reply, "我会轻轻陪着你。")
        self.assertEqual(captured["payload"]["model"], "deepseek-v4-flash")
        self.assertEqual(captured["payload"]["thinking"], {"type": "disabled"})
        self.assertEqual(captured["payload"]["max_tokens"], 700)
        self.assertFalse(captured["payload"]["stream"])
        self.assertEqual(captured["headers"]["Authorization"], "Bearer test-key")
        self.assertEqual(captured["timeout"], 12)


if __name__ == "__main__":
    unittest.main()
