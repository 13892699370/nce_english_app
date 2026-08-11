import 'lesson.dart';

/// 新概念英语第一册课程标题（共 144 课）
///
/// 仅维护“数据”，业务逻辑在 [TextbookRegistry] 中统一处理。
/// 后续新增 NCE2/NCE3 时，只需新增数据源文件，无需改动业务代码。
const List<String> nce1LessonTitles = [
  'Excuse me!', // 1
  'Sorry, sir.', // 2
  'Nice to meet you.', // 3
  'Is this your...?', // 4
  'Nice to meet you, too.', // 5
  'What make is it?', // 6
  'Are you a teacher?', // 7
  "What's your job?", // 8
  'How are you today?', // 9
  'Look at...', // 10
  'Is this your shirt?', // 11
  'This is our...', // 12
  'A new dress', // 13
  "What colour's your...?", // 14
  'Your passports, please.', // 15
  'Are you...?', // 16
  'How do you do?', // 17
  'What are their jobs?', // 18
  'Tired and thirsty', // 19
  'Look at them!', // 20
  'Which book?', // 21
  'Give me/him/her/us/them a...', // 22
  'Which glasses?', // 23
  'Give me some...', // 24
  "Mrs. Smith's kitchen", // 25
  'Where is it?', // 26
  "Mrs. Smith's living room", // 27
  'Where are they?', // 28
  'Come in, Amy.', // 29
  'What must I do?', // 30
  "Where's Sally?", // 31
  'He, she and they', // 32
  'A fine day', // 33
  'What are they doing?', // 34
  'Our village', // 35
  'Where...?', // 36
  'Making a bookcase', // 37
  'What are you going to do?', // 38
  "Don't drop it!", // 39
  'What are you going to do?', // 40
  "Penny's bag", // 41
  'Is there a...in/on that...?', // 42
  'Hurry up!', // 43
  'Are there any...?', // 44
  "The boss's letter", // 45
  'Can you...?', // 46
  'A cup of coffee', // 47
  'Do you like...?', // 48
  "At the butcher's", // 49
  'He likes...', // 50
  'A pleasant climate', // 51
  'What nationality are they?', // 52
  'An interesting climate', // 53
  'What country do they come from?', // 54
  'The Sawyer family', // 55
  'An unusual day', // 56
  'An unusual day', // 57
  'A lucky girl', // 58
  'Is that the best...?', // 59
  'The best and the worst', // 60
  'A bad cold', // 61
  "What's the matter with them?", // 62
  'Thank you, doctor.', // 63
  "Don't...!", // 64
  'Not a baby', // 65
  "What's the time?", // 66
  'The weekend', // 67
  'When did they...?', // 68
  'The car race', // 69
  'When were they there?', // 70
  "He's awful!", // 71
  'What did they do...?', // 72
  'The way to King Street', // 73
  'What did they do?', // 74
  'Uncomfortable shoes', // 75
  'When did you...?', // 76
  'Terrible toothache', // 77
  'What time...?', // 78
  "Carol's shopping list", // 79
  'I hope that you...', // 80
  'Roast beef and potatoes', // 81
  'I had...', // 82
  'Going on holiday', // 83
  "I've already had...", // 84
  'Paris in the spring', // 85
  'What have you done?', // 86
  'A car crash', // 87
  'Have you...yet?', // 88
  'For sale', // 89
  'Have you...yet?', // 90
  'Poor Ian!', // 91
  'When will...?', // 92
  'Our new neighbour', // 93
  'When did he/will he...?', // 94
  'Tickets, please.', // 95
  'What time will...?', // 96
  'A small blue case', // 97
  'Whose is it?', // 98
  'Ow!', // 99
  'I think that...', // 100
  'A card from Jimmy', // 101
  'He says that...', // 102
  'The French test', // 103
  'Too, very, enough', // 104
  'Full of mistakes', // 105
  'I want you to.../Tell him to...', // 106
  "It's too small.", // 107
  'I want you to...him to...', // 108
  'A good idea', // 109
  'How do they compare?', // 110
  'The most expensive model', // 111
  'How do they compare?', // 112
  'Small change', // 113
  "I've got none.", // 114
  'Knock, knock!', // 115
  'Every, no, any and some', // 116
  "Tommy's breakfast", // 117
  'What were you doing?', // 118
  'A true story', // 119
  'What were they doing?', // 120
  'The man in a hat', // 121
  'Who(whom), which and that', // 122
  'A trip to Australia', // 123
  '(Who)to, (to)whom, ...', // 124
  'Tea for two', // 125
  'Have to and do not need to', // 126
  'A famous actor', // 127
  "He can't be...", // 128
  'Seventy miles an hour', // 129
  "He can't have been...", // 130
  "Don't be so sure!", // 131
  'He may be...', // 132
  'Sensational news!', // 133
  'He said(that)he...', // 134
  'The latest report', // 135
  'He said(that)he...(He told me that he...)', // 136
  'A pleasant dream', // 137
  'If...', // 138
  'Is that you, John?', // 139
  'He wants to know if/why/what/when', // 140
  "Sally's first train ride", // 141
  'Someone invited Sally to a party.', // 142
  'A walk through the woods', // 143
  "He hasn't been found yet.", // 144
];

/// 新概念英语第一册词库（示例核心词，按课次组织）
///
/// 后续可继续向此列表追加单词，业务代码无需改动。
const List<VocabWord> nce1Vocab = [
  VocabWord(word: 'excuse', phonetic: '/ɪkˈskjuːz/', meaning: 'v. 原谅', lessonNumber: 1),
  VocabWord(word: 'me', phonetic: '/miː/', meaning: 'pron. 我（宾格）', lessonNumber: 1),
  VocabWord(word: 'handbag', phonetic: '/ˈhændbæɡ/', meaning: 'n. 手提包', lessonNumber: 1),
  VocabWord(word: 'pardon', phonetic: '/ˈpɑːdn/', meaning: 'int. 原谅，再说一遍', lessonNumber: 1),
  VocabWord(word: 'pen', phonetic: '/pen/', meaning: 'n. 钢笔', lessonNumber: 1),
  VocabWord(word: 'pencil', phonetic: '/ˈpensl/', meaning: 'n. 铅笔', lessonNumber: 1),
  VocabWord(word: 'book', phonetic: '/bʊk/', meaning: 'n. 书', lessonNumber: 1),
  VocabWord(word: 'watch', phonetic: '/wɒtʃ/', meaning: 'n. 手表', lessonNumber: 1),
  VocabWord(word: 'coat', phonetic: '/kəʊt/', meaning: 'n. 外套', lessonNumber: 3),
  VocabWord(word: 'dress', phonetic: '/dres/', meaning: 'n. 连衣裙', lessonNumber: 3),
  VocabWord(word: 'shirt', phonetic: '/ʃɜːt/', meaning: 'n. 衬衫', lessonNumber: 3),
  VocabWord(word: 'car', phonetic: '/kɑː/', meaning: 'n. 小汽车', lessonNumber: 5),
  VocabWord(word: 'house', phonetic: '/haʊs/', meaning: 'n. 房子', lessonNumber: 5),
  VocabWord(word: 'suit', phonetic: '/suːt/', meaning: 'n. 一套衣服', lessonNumber: 5),
  VocabWord(word: 'school', phonetic: '/skuːl/', meaning: 'n. 学校', lessonNumber: 5),
  VocabWord(word: 'teacher', phonetic: '/ˈtiːtʃə/', meaning: 'n. 老师', lessonNumber: 7),
  VocabWord(word: 'student', phonetic: '/ˈstjuːdnt/', meaning: 'n. 学生', lessonNumber: 7),
  VocabWord(word: 'keyboard', phonetic: '/ˈkiːbɔːd/', meaning: 'n. 键盘', lessonNumber: 7),
  VocabWord(word: 'operator', phonetic: '/ˈɒpəreɪtə/', meaning: 'n. 操作员', lessonNumber: 7),
  VocabWord(word: 'engineer', phonetic: '/ˌendʒɪˈnɪə/', meaning: 'n. 工程师', lessonNumber: 7),
  VocabWord(word: 'policeman', phonetic: '/pəˈliːsmən/', meaning: 'n. 警察', lessonNumber: 7),
  VocabWord(word: 'policewoman', phonetic: '/pəˈliːswʊmən/', meaning: 'n. 女警察', lessonNumber: 7),
  VocabWord(word: 'taxi driver', phonetic: '/ˈtæksi draɪvə/', meaning: 'n. 出租车司机', lessonNumber: 7),
  VocabWord(word: 'postman', phonetic: '/ˈpəʊstmən/', meaning: 'n. 邮递员', lessonNumber: 7),
  VocabWord(word: 'nurse', phonetic: '/nɜːs/', meaning: 'n. 护士', lessonNumber: 7),
  VocabWord(word: 'mechanic', phonetic: '/məˈkænɪk/', meaning: 'n. 机械师', lessonNumber: 7),
  VocabWord(word: 'hairdresser', phonetic: '/ˈheədresə/', meaning: 'n. 理发师', lessonNumber: 7),
  VocabWord(word: 'housewife', phonetic: '/ˈhaʊswaɪf/', meaning: 'n. 家庭妇女', lessonNumber: 7),
  VocabWord(word: 'milkman', phonetic: '/ˈmɪlkmən/', meaning: 'n. 送牛奶的人', lessonNumber: 7),
  VocabWord(word: 'hello', phonetic: '/həˈləʊ/', meaning: 'int. 喂（你好）', lessonNumber: 9),
  VocabWord(word: 'hi', phonetic: '/haɪ/', meaning: 'int. 喂，你好', lessonNumber: 9),
  VocabWord(word: 'how', phonetic: '/haʊ/', meaning: 'adv. 怎样', lessonNumber: 9),
  VocabWord(word: 'today', phonetic: '/təˈdeɪ/', meaning: 'adv. 今天', lessonNumber: 9),
  VocabWord(word: 'well', phonetic: '/wel/', meaning: 'adj. 身体好', lessonNumber: 9),
  VocabWord(word: 'fine', phonetic: '/faɪn/', meaning: 'adj. 美好的', lessonNumber: 9),
  VocabWord(word: 'thanks', phonetic: '/θæŋks/', meaning: 'int. 谢谢', lessonNumber: 9),
  VocabWord(word: 'goodbye', phonetic: '/ˌɡʊdˈbaɪ/', meaning: 'int. 再见', lessonNumber: 9),
  VocabWord(word: 'see', phonetic: '/siː/', meaning: 'v. 见', lessonNumber: 9),
  VocabWord(word: 'fat', phonetic: '/fæt/', meaning: 'adj. 胖的', lessonNumber: 11),
  VocabWord(word: 'thin', phonetic: '/θɪn/', meaning: 'adj. 瘦的', lessonNumber: 11),
  VocabWord(word: 'tall', phonetic: '/tɔːl/', meaning: 'adj. 高的', lessonNumber: 11),
  VocabWord(word: 'short', phonetic: '/ʃɔːt/', meaning: 'adj. 矮的', lessonNumber: 11),
  VocabWord(word: 'dirty', phonetic: '/ˈdɜːti/', meaning: 'adj. 脏的', lessonNumber: 11),
  VocabWord(word: 'clean', phonetic: '/kliːn/', meaning: 'adj. 干净的', lessonNumber: 11),
  VocabWord(word: 'hot', phonetic: '/hɒt/', meaning: 'adj. 热的', lessonNumber: 11),
  VocabWord(word: 'cold', phonetic: '/kəʊld/', meaning: 'adj. 冷的', lessonNumber: 11),
  VocabWord(word: 'old', phonetic: '/əʊld/', meaning: 'adj. 老的', lessonNumber: 11),
  VocabWord(word: 'young', phonetic: '/jʌŋ/', meaning: 'adj. 年轻的', lessonNumber: 11),
  VocabWord(word: 'busy', phonetic: '/ˈbɪzi/', meaning: 'adj. 忙的', lessonNumber: 11),
  VocabWord(word: 'lazy', phonetic: '/ˈleɪzi/', meaning: 'adj. 懒的', lessonNumber: 11),
  VocabWord(word: 'colour', phonetic: '/ˈkʌlə/', meaning: 'n. 颜色', lessonNumber: 13),
  VocabWord(word: 'green', phonetic: '/ɡriːn/', meaning: 'adj. 绿色', lessonNumber: 13),
  VocabWord(word: 'red', phonetic: '/red/', meaning: 'adj. 红色', lessonNumber: 13),
  VocabWord(word: 'smart', phonetic: '/smɑːt/', meaning: 'adj. 时髦的，漂亮的', lessonNumber: 13),
  VocabWord(word: 'hat', phonetic: '/hæt/', meaning: 'n. 帽子', lessonNumber: 13),
  VocabWord(word: 'same', phonetic: '/seɪm/', meaning: 'adj. 相同的', lessonNumber: 13),
  VocabWord(word: 'lovely', phonetic: '/ˈlʌvli/', meaning: 'adj. 可爱的，秀美的', lessonNumber: 13),
  VocabWord(word: 'case', phonetic: '/keɪs/', meaning: 'n. 箱子', lessonNumber: 15),
  VocabWord(word: 'carpet', phonetic: '/ˈkɑːpɪt/', meaning: 'n. 地毯', lessonNumber: 25),
  VocabWord(word: 'cup', phonetic: '/kʌp/', meaning: 'n. 茶杯', lessonNumber: 27),
  VocabWord(word: 'kitchen', phonetic: '/ˈkɪtʃɪn/', meaning: 'n. 厨房', lessonNumber: 25),
  VocabWord(word: 'refrigerator', phonetic: '/rɪˈfrɪdʒəreɪtə/', meaning: 'n. 冰箱', lessonNumber: 25),
];
