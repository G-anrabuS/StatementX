import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import markdown package
import '../services/statement_service.dart';
import '../theme/app_theme.dart';

class ChatBotScreen extends StatefulWidget {
  final String statementId;

  const ChatBotScreen({
    super.key,
    required this.statementId,
  });

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  // Update to track raw JSON string responses or source blocks if provided
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendMessage() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _isLoading = true;
    });

    try {
      // API client function signature handles structured history
      final reply = await StatementService.chatWithStatement(
        statementId: widget.statementId,
        message: query,
        chatHistory: _messages
            .map((m) => {
                  'sender': m['sender'].toString(),
                  'text': (m['text'] ?? '').toString(),
                })
            .toList(),
      );

      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': reply, // Raw Markdown text response string rendered natively
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Failed to process semantic ledger request: $e',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Semantic Document Query',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Ask questions like: "What subscription renewals happened in June?"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, idx) {
                      final msg = _messages[idx];
                      final isUser = msg['sender'] == 'user';
                      final textContent = msg['text'] ?? '';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.85),
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.secondaryTeal : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: isUser ? null : Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isUser
                              ? Text(
                                  textContent,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Render native Markdown bodies, tables, and lists beautifully
                                    MarkdownBody(
                                      data: textContent,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                                        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, height: 1.8),
                                        strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        tableHead: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        tableBody: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        tableBorder: TableBorder.all(color: AppColors.borderLight, width: 1),
                                        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surfaceLight,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask your bank statement...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.secondaryTeal),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
