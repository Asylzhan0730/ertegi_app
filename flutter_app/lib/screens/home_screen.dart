import 'package:flutter/material.dart';
import '../services/tts_service.dart';

import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/message_bubble.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class HomeScreen extends StatefulWidget {
  final bool isAuth;

  const HomeScreen({
    super.key,
    this.isAuth = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService tts = TtsService();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController inputCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  bool loading = false;
  bool isAuth = false;

  String lastPrompt = '';
  String lastStory = '';

  String? email;
  String ageCategory = '5+';
  String selectedCategoryKey = 'classic';

  final List<String> ageItems = ['1-2', '3-4', '5+'];

  final List<String> categoryKeys = [
    'classic',
    'animals',
    'magic',
    'educational',
    'short',
  ];

  String tr(String kk, String ru, String en) {
    switch (languageNotifier.value) {
      case AppLanguage.ru:
        return ru;
      case AppLanguage.en:
        return en;
      case AppLanguage.kk:
        return kk;
    }
  }

  String get categoryName {
    return categoryTitle(selectedCategoryKey);
  }

  String categoryTitle(String key) {
    switch (key) {
      case 'animals':
        return tr('Жануарлар', 'Животные', 'Animals');
      case 'magic':
        return tr('Сиқырлы ертегі', 'Волшебная сказка', 'Magic tale');
      case 'educational':
        return tr('Тәрбиелік ертегі', 'Поучительная сказка', 'Educational tale');
      case 'short':
        return tr('Қысқа ертегі', 'Короткая сказка', 'Short tale');
      case 'classic':
      default:
        return tr('Классикалық ертегі', 'Классическая сказка', 'Classic tale');
    }
  }

  List<ChatMessage> get initialMessages => [
    ChatMessage(
      text: tr(
        'Сәлем, балақай! 🌟 Мен саған ертегілер айтып беремін.',
        'Привет! 🌟 Я расскажу тебе сказки. Сейчас включён гостевой режим.',
        'Hello! 🌟 I can tell you fairy tales. Guest Mode is active now.',
      ),
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    isAuth = widget.isAuth;
    messages.addAll(initialMessages);
    loadAuth();
  }

  final List<ChatMessage> messages = [];

  Future<void> loadAuth() async {
    final token = await AuthStorage.getToken();
    final savedEmail = await AuthStorage.getEmail();
    final savedAge = await AuthStorage.getAgeCategory();

    if (!mounted) return;

    setState(() {
      isAuth = token != null && token.isNotEmpty;
      email = savedEmail;
      ageCategory = savedAge ?? '5+';
    });
  }

  void resetWelcomeMessage() {
    setState(() {
      messages.clear();
      messages.addAll(initialMessages);
    });
  }

  void addBot(String text) {
    setState(() {
      messages.add(ChatMessage(text: text, isUser: false));
    });
    scrollDown();
  }

  void scrollDown() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!scrollCtrl.hasClients) return;

      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> openLogin() async {
    Navigator.pop(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result == true) {
      await loadAuth();
      addBot(tr(
        'Керемет! ✅ Сіз жүйеге кірдіңіз.',
        'Отлично! ✅ Вы вошли в аккаунт.',
        'Great! ✅ You are signed in.',
      ));
    }
  }

  Future<void> openRegister() async {
    Navigator.pop(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );

    if (result == true) {
      await loadAuth();
      addBot(tr(
        'Тамаша! 🎉 Тіркелу сәтті өтті.',
        'Отлично! 🎉 Регистрация прошла успешно.',
        'Awesome! 🎉 Registration was successful.',
      ));
    }
  }

  Future<void> logout() async {
    Navigator.pop(context);

    await AuthStorage.logout();

    setState(() {
      isAuth = false;
      email = null;
      ageCategory = '5+';
      lastPrompt = '';
      lastStory = '';
      messages.clear();
      messages.add(
        ChatMessage(
          text: tr(
            'Сіз Guest Mode режиміне өттіңіз. Ертегілер базаға сақталмайды.',
            'Вы перешли в гостевой режим. Сказки не будут сохраняться.',
            'You switched to Guest Mode. Stories will not be saved.',
          ),
          isUser: false,
        ),
      );
    });
  }

  Future<void> saveFilter(String value) async {
    setState(() {
      ageCategory = value;
    });

    if (!isAuth) {
      addBot(tr(
        'Жас тобы уақытша таңдалды. Сақтау үшін кіріңіз немесе тіркеліңіз.',
        'Возраст выбран временно. Чтобы сохранить, войдите или зарегистрируйтесь.',
        'Age group selected temporarily. Sign in or register to save it.',
      ));
      return;
    }

    try {
      await ApiService.saveFilter(value);
      await AuthStorage.saveAgeCategory(value);
      addBot(tr(
        'Жас фильтрі сақталды: $value ✅',
        'Возрастной фильтр сохранён: $value ✅',
        'Age filter saved: $value ✅',
      ));
    } catch (e) {
      addBot(tr(
        'Фильтр сақтау қатесі: $e',
        'Ошибка сохранения фильтра: $e',
        'Filter save error: $e',
      ));
    }
  }

  Future<void> saveCurrentStory() async {
    if (!isAuth) {
      addBot(tr(
        'Ертегіні сақтау үшін кіріңіз немесе тіркеліңіз.',
        'Чтобы сохранить сказку, войдите или зарегистрируйтесь.',
        'Sign in or register to save the story.',
      ));
      return;
    }

    if (lastStory.trim().isEmpty) {
      addBot(tr(
        'Алдымен ертегі құрастырыңыз.',
        'Сначала создайте сказку.',
        'Create a story first.',
      ));
      return;
    }

    try {
      await ApiService.saveStory(
        prompt: lastPrompt,
        story: lastStory,
      );

      addBot(tr(
        '📚 Ертегі тарихқа сақталды!',
        '📚 Сказка сохранена в историю!',
        '📚 Story saved to history!',
      ));
    } catch (e) {
      addBot(tr(
        'Сақтау қатесі: $e',
        'Ошибка сохранения: $e',
        'Save error: $e',
      ));
    }
  }

  Future<void> loadHistory() async {
    if (!isAuth) {
      addBot(tr(
        'Тарихты көру үшін кіріңіз немесе тіркеліңіз.',
        'Чтобы посмотреть историю, войдите или зарегистрируйтесь.',
        'Sign in or register to view history.',
      ));
      return;
    }

    try {
      final data = await ApiService.getStories();
      final List stories = data['stories'] ?? [];

      if (stories.isEmpty) {
        addBot(tr(
          'Сақталған ертегілер әлі жоқ.',
          'Сохранённых сказок пока нет.',
          'There are no saved stories yet.',
        ));
        return;
      }

      setState(() {
        messages.clear();

        messages.add(
          ChatMessage(
            text: tr(
              '📚 Сақталған ертегілер:',
              '📚 Сохранённые сказки:',
              '📚 Saved stories:',
            ),
            isUser: false,
          ),
        );

        for (final item in stories.take(10)) {
          messages.add(
            ChatMessage(
              text: tr(
                '🧒 Сұраныс: ${item['prompt'] ?? ''}\n\n📖 Ертегі:\n${item['story'] ?? ''}',
                '🧒 Запрос: ${item['prompt'] ?? ''}\n\n📖 Сказка:\n${item['story'] ?? ''}',
                '🧒 Prompt: ${item['prompt'] ?? ''}\n\n📖 Story:\n${item['story'] ?? ''}',
              ),
              isUser: false,
            ),
          );
        }
      });

      scrollDown();
    } catch (e) {
      addBot(tr(
        'Тарихты жүктеу қатесі: $e',
        'Ошибка загрузки истории: $e',
        'History loading error: $e',
      ));
    }
  }

  Future<void> sendMessage({String? customPrompt}) async {
    final text = customPrompt ?? inputCtrl.text.trim();

    if (text.isEmpty || loading) return;

    inputCtrl.clear();

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      loading = true;
    });

    scrollDown();

    try {
      final data = await ApiService.generateStory(
        prompt: text,
        ageCategory: ageCategory,
        category: categoryName,
        language: LanguageService.code,
      );

      final story = data['story']?.toString();

      lastPrompt = text;
      lastStory = story ?? '';

      setState(() {
        messages.add(
          ChatMessage(
            text: story == null || story.isEmpty
                ? tr(
              'AI жауап бермеді. OpenRouter API тексеріңіз.',
              'AI не ответил. Проверьте OpenRouter API.',
              'AI did not respond. Check OpenRouter API.',
            )
                : story,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        messages.add(
          ChatMessage(
            text: tr(
              'Қате шықты: $e\n\nТексер:\n1) backend қосулы ма: npm start\n2) OPENROUTER_API_KEY бар ма\n3) API URL дұрыс па: http://localhost:3000',
              'Ошибка: $e\n\nПроверь:\n1) включён ли backend: npm start\n2) есть ли OPENROUTER_API_KEY\n3) правильный ли API URL: http://localhost:3000',
              'Error: $e\n\nCheck:\n1) is backend running: npm start\n2) is OPENROUTER_API_KEY set\n3) is API URL correct: http://localhost:3000',
            ),
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      scrollDown();
    }
  }

  Future<void> changeLanguage(AppLanguage language) async {
    await LanguageService.setLanguage(language);

    if (!mounted) return;

    Navigator.pop(context);
    Navigator.pop(context);

    setState(() {
      selectedCategoryKey = selectedCategoryKey;
    });

    resetWelcomeMessage();
  }

  Widget buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
              const Color(0xFF1E1E1E),
              const Color(0xFF311B92),
            ]
                : [
              const Color(0xFFFFF3E0),
              const Color(0xFFF3E5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFF6A1B9A),
                      child: Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr('Ертегі AI', 'Сказки AI', 'Fairy Tale AI'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAuth
                          ? tr('Аккаунт: $email', 'Аккаунт: $email', 'Account: $email')
                          : 'Guest Mode',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(height: 32),
                    if (!isAuth) ...[
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: Text(tr('Кіру', 'Войти', 'Sign in')),
                        onTap: openLogin,
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: Text(tr('Тіркелу', 'Регистрация', 'Register')),
                        onTap: openRegister,
                      ),
                    ],
                    if (isAuth) ...[
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(tr(
                          'Менің ертегілерім',
                          'Мои сказки',
                          'My stories',
                        )),
                        onTap: () {
                          Navigator.pop(context);
                          loadHistory();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: Text(tr('Шығу', 'Выйти', 'Sign out')),
                        onTap: logout,
                      ),
                    ],
                    ListTile(
                      leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      title: Text(
                        isDark
                            ? tr('Жарық режим', 'Светлая тема', 'Light mode')
                            : tr('Қараңғы режим', 'Тёмная тема', 'Dark mode'),
                      ),
                      onTap: () async {
                        await AppTheme.toggleTheme();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(tr(
                        'Тіл',
                        'Язык',
                        'Language',
                      )),
                      subtitle: Text(LanguageService.languageName(languageNotifier.value)),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Text('🇰🇿'),
                                    title: const Text('Қазақша'),
                                    onTap: () => changeLanguage(AppLanguage.kk),
                                  ),
                                  ListTile(
                                    leading: const Text('🇷🇺'),
                                    title: const Text('Русский'),
                                    onTap: () => changeLanguage(AppLanguage.ru),
                                  ),
                                  ListTile(
                                    leading: const Text('🇬🇧'),
                                    title: const Text('English'),
                                    onTap: () => changeLanguage(AppLanguage.en),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      isAuth
                          ? tr(
                        'Сіз толық режимдесіз. Ертегілер сақталады.',
                        'Вы в полном режиме. Сказки сохраняются.',
                        'Full mode is active. Stories are saved.',
                      )
                          : tr(
                        'Guest Mode: ертегілер базаға сақталмайды.',
                        'Guest Mode: сказки не сохраняются.',
                        'Guest Mode: stories are not saved.',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7E57C2),
            Color(0xFFFFB74D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('Қазақша Ертегі AI', 'Сказки AI', 'Fairy Tale AI'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text('🌙 ⭐', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAuth
                ? tr(
              'Қош келдіңіз! Ертегі әлеміне саяхат жасайық.',
              'Добро пожаловать! Отправимся в мир сказок.',
              'Welcome! Let’s travel into the world of fairy tales.',
            )
                : tr(
              'Guest Mode: ертегі тыңдай аласыз, сақтау үшін кіріңіз.',
              'Guest Mode: можно слушать сказки, для сохранения войдите.',
              'Guest Mode: you can listen to stories, sign in to save them.',
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('👶 Жас таңдаңыз:', '👶 Выберите возраст:', '👶 Choose age:'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ageItems.map((item) {
              final isSelected = ageCategory == item;

              return ChoiceChip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => saveFilter(item),
                selectedColor: const Color(0xFF6A1B9A),
                backgroundColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade200,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6A1B9A)
                      : (isDark ? Colors.white24 : Colors.grey.shade400),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            tr('📚 Ертегі түрі:', '📚 Тип сказки:', '📚 Story type:'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCategoryKey,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFFFF8E1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: categoryKeys.map((key) {
              return DropdownMenuItem(
                value: key,
                child: Text(categoryTitle(key)),
              );
            }).toList(),
            onChanged: loading
                ? null
                : (value) {
              if (value == null) return;
              setState(() {
                selectedCategoryKey = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildQuickButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () => sendMessage(
                    customPrompt: tr(
                      'Ертегі жаз. Түрі: $categoryName. Жас тобы: $ageCategory.',
                      'Напиши сказку. Тип: $categoryName. Возраст: $ageCategory.',
                      'Write a fairy tale. Type: $categoryName. Age group: $ageCategory.',
                    ),
                  ),
                  icon: const Icon(Icons.auto_stories, color: Colors.white),
                  label: Text(
                    tr('Ертегі құрастыру', 'Создать сказку', 'Create story'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    disabledBackgroundColor: const Color(0xFF4A148C),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => sendMessage(
                    customPrompt: tr(
                      'Келесі жаңа ертегіні жаз. Бұрынғысын қайталама. Түрі: $categoryName. Жас тобы: $ageCategory.',
                      'Напиши следующую новую сказку. Не повторяй предыдущую. Тип: $categoryName. Возраст: $ageCategory.',
                      'Write the next new fairy tale. Do not repeat the previous one. Type: $categoryName. Age group: $ageCategory.',
                    ),
                  ),
                  icon: const Icon(Icons.navigate_next),
                  label: Text(
                    tr('Келесі', 'Следующая', 'Next'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAuth)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: loading || lastStory.isEmpty ? null : saveCurrentStory,
                icon: const Icon(Icons.bookmark_add, color: Colors.white),
                label: Text(
                  tr(
                    'Тарихқа сақтау',
                    'Сохранить в историю',
                    'Save to history',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputCtrl,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tr(
                    'Мысалы: Бауырсақ ертегісін айтып бер',
                    'Например: расскажи сказку Колобок',
                    'Example: tell me the Kolobok story',
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onSubmitted: (_) {
                  if (!loading) sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: loading ? null : () => sendMessage(),
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingBubble() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(tr(
              'Ертегі жазылып жатыр... ✨',
              'Сказка пишется... ✨',
              'Writing the story... ✨',
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      endDrawer: buildDrawer(),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF7F0),
      appBar: AppBar(
        title: Text(tr('Ертегі әлемі', 'Мир сказок', 'Fairy Tale World')),
        actions: [
          IconButton(
            onPressed: () {
              scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: Column(
        children: [
          buildHeader(),
          buildFilter(),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(14),
              itemCount: messages.length + (loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (loading && index == messages.length) {
                  return buildLoadingBubble();
                }

                final msg = messages[index];

                return Column(
                  crossAxisAlignment:
                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    MessageBubble(
                      text: msg.text,
                      isUser: msg.isUser,
                    ),
                    if (!msg.isUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () {
                                tts.speak(msg.text);
                              },
                              icon: const Icon(Icons.play_arrow),
                              tooltip: 'Оқып беру',
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              onPressed: () {
                                tts.pause();
                              },
                              icon: const Icon(Icons.pause),
                              tooltip: 'Пауза',
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              onPressed: () {
                                tts.stop();
                              },
                              icon: const Icon(Icons.stop),
                              tooltip: 'Тоқтату',
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          buildQuickButtons(),
          buildInput(),
        ],
      ),
    );
  }
}
