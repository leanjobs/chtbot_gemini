import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}
final String _apiKey = dotenv.env['_apiKey'] ?? "";


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    _chat = _model.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
    });
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      setState(() {
        _messages.add(ChatMessage(text: text!, isUser: false));
        _scrollDown();
      });
    } catch (e) {
      print("errorrr $e");
      setState(() {
        _messages.add(ChatMessage(text: "Error occured", isUser: false));
      });
    } finally {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("AI ChatBot"),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return ChatBubble(message: _messages[index]);
            },
          )),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  onSubmitted: _sendChatMessage,
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "Type a message",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
                IconButton(
                  onPressed: () => _sendChatMessage(_textController.text),
                  icon: Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 1.25,
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
              color: message.isUser
                  ? Color(0xFF8BB1F2).withOpacity(0.5)
                  : Color(0xFFDB8CFD).withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: message.isUser ? Radius.circular(12) : Radius.zero,
                bottomRight: message.isUser ? Radius.zero : Radius.circular(12),
              )),
          child: MarkdownBody(
            data: message.text,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 16),
              strong: TextStyle(fontWeight: FontWeight.bold),
              em: TextStyle(fontStyle: FontStyle.italic),
            ),
          )),
    );
  }
}
