# Raw Idea: Critical Bug Fixes

Fix all critical and high severity issues identified in code_review2.md:

CRITICAL ISSUES (Must fix immediately):
1. Connection timeout exception not propagated in bluetooth_service.dart - timeout thrown in Timer callback is never caught
2. Settings provider returns defaults before async loading completes - causes UI to flash wrong data
3. Stream subscription memory leak - multiple subscriptions created without cancelling previous ones
4. Race condition in reconnection monitoring - multiple concurrent reconnection attempts possible
5. Weak backup encryption using XOR cipher instead of proper AES encryption

HIGH PRIORITY ISSUES:
6. Unencrypted desktop database - SQLite on Linux/Windows/macOS stores health data in plaintext
7. Permission check failure mishandled - assumes no permissions when check itself fails
8. Race condition: timeout fires after successful connection if service discovery is slow
9. Empty session statistics edge case - sessions with no readings saved with null stats
10. Stream controller not closed in error paths - resource leak in demo mode errors

This is a bug fix and code quality improvement project to address security vulnerabilities, race conditions, memory leaks, and UX issues.
