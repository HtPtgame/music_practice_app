// lib/services/joke_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 冷笑話服務 - 音樂專業術語教學導向
/// 透過諧音梗、雙關、幽默情境讓用戶輕鬆學習音樂術語
class JokeService {
  static final JokeService _instance = JokeService._internal();
  factory JokeService() => _instance;
  JokeService._internal();

  final Random _random = Random();

  // 以洗牌序列避免短時間重複
  List<int> _shuffledIndices = [];
  int _cursor = 0;

  /// 音樂術語教學笑話庫
  /// setup: 問題/情境
  /// punchline: 答案/梗
  /// explain: 專業術語解釋 + 幽默點說明
  /// tag: 術語分類
  final List<Map<String, String>> _jokes = [
    // ===== 速度術語 (Tempo) =====
    {
      'setup': '為什麼 Largo 總是遲到？',
      'punchline': '因為他走得太「緩慢」，連鬧鐘都追不上！',
      'explain': '🎵 Largo = 極緩板（40-60 BPM）\n義大利文原意「寬廣」，用於音樂表示非常緩慢、莊嚴的速度。',
      'tag': '速度術語',
    },
    {
      'setup': 'Presto 去速食店點餐會怎樣？',
      'punchline': '店員還沒聽清楚，他已經吃完走人了！',
      'explain': '🎵 Presto = 急板（168-200 BPM）\n義大利文「快速」之意，是最快的速度記號之一，常用於激昂樂段。',
      'tag': '速度術語',
    },
    {
      'setup': 'Andante 去散步，為什麼朋友都不想等他？',
      'punchline': '因為他說「慢慢走才能欣賞風景」，結果變成龜速！',
      'explain': '🎵 Andante = 行板（76-108 BPM）\n義大利文「行走」之意，像散步般的中等速度，平穩而不急促。',
      'tag': '速度術語',
    },
    {
      'setup': 'Allegro 去約會，為什麼女友很生氣？',
      'punchline': '因為他說「快樂就好」，結果吃飯點菜都用搶的！',
      'explain': '🎵 Allegro = 快板（120-168 BPM）\n義大利文「快樂、輕快」，表示輕快活潑的速度。',
      'tag': '速度術語',
    },
    {
      'setup': 'Adagio 開車時最常被按喇叭，為什麼？',
      'punchline': '因為他把「從容不迫」當成龜速開車的藉口！',
      'explain': '🎵 Adagio = 柔板（66-76 BPM）\n義大利文「從容」之意，速度較慢且具抒情性，常用於慢樂章。',
      'tag': '速度術語',
    },

    // ===== 力度術語 (Dynamics) =====
    {
      'setup': 'Piano 去圖書館，為什麼館員都愛他？',
      'punchline': '因為他說話總是「輕聲細語」！',
      'explain': '🎵 Piano (p) = 弱奏\n義大利文「柔和、安靜」，記號 p，表示演奏音量要輕柔。',
      'tag': '力度術語',
    },
    {
      'setup': 'Forte 去 KTV，為什麼老闆請他出去？',
      'punchline': '因為他唱什麼都像在「吼」！隔壁包廂都抗議了！',
      'explain': '🎵 Forte (f) = 強奏\n義大利文「強烈」，記號 f，表示要用強大音量演奏。',
      'tag': '力度術語',
    },
    {
      'setup': 'Crescendo 去吃到飽，為什麼老闆嚇到？',
      'punchline': '因為他的食量「漸強」，從一盤變成十盤！',
      'explain': '🎵 Crescendo (cresc.) = 漸強\n記號 <，表示音量逐漸增強，營造情緒推進感。',
      'tag': '力度術語',
    },
    {
      'setup': 'Diminuendo 講故事，為什麼大家都睡著？',
      'punchline': '因為他越講越小聲，最後連自己都聽不到！',
      'explain': '🎵 Diminuendo (dim.) = 漸弱\n記號 >，表示音量逐漸減弱，營造淡出效果。',
      'tag': '力度術語',
    },
    {
      'setup': 'Fortissimo 去抱怨，為什麼大樓都聽到？',
      'punchline': '因為他的「非常強」連三條街外都震動！',
      'explain': '🎵 Fortissimo (ff) = 極強\n比 Forte 更強的音量，需要全力以赴的演奏力度。',
      'tag': '力度術語',
    },

    // ===== 音符時值 (Note Values) =====
    {
      'setup': '全音符去約會，為什麼女友都等睡著？',
      'punchline': '因為他要「撐滿整個小節」，一等就是 4 拍！',
      'explain': '🎵 全音符 (Whole Note) = 4 拍\n記號 𝅝，在 4/4 拍中占滿整個小節的時值。',
      'tag': '音符時值',
    },
    {
      'setup': '十六分音符跑步，為什麼總是摔倒？',
      'punchline': '因為他跑太快，一拍要跑四步，根本剎不住車！',
      'explain':
          '🎵 十六分音符 (Sixteenth Note) = 1/4 拍\n記號 𝅘𝅥𝅯，一拍可分為 4 個十六分音符，速度極快。',
      'tag': '音符時值',
    },
    {
      'setup': '附點音符去吃飯，為什麼店員很困惑？',
      'punchline': '因為他說「我要加半份」，店員問：半份什麼？',
      'explain':
          '🎵 附點 (Dotted Note) = 原時值 + 一半\n記號在音符後加點 (•)，例如附點二分音符 = 3 拍（2+1）。',
      'tag': '音符時值',
    },
    {
      'setup': '休止符去面試，為什麼被刷掉？',
      'punchline': '因為他全程「保持安靜」，一句話都不說！',
      'explain':
          '🎵 休止符 (Rest) = 停頓標記\n記號如 𝄽（全休止）、𝄾（二分休止），表示該拍不發聲，留白也是音樂的一部分。',
      'tag': '音符時值',
    },

    // ===== 調性術語 (Key & Scale) =====
    {
      'setup': '大調先生總是笑嘻嘻，為什麼？',
      'punchline': '因為他的世界都是「明亮陽光」，連烏雲都是白色的！',
      'explain': '🎵 大調 (Major Scale) = 明亮歡快\n音階結構：全全半全全全半，給人開朗、正面的感覺。',
      'tag': '調性術語',
    },
    {
      'setup': '小調小姐為什麼常常哭？',
      'punchline': '因為她的心情總是「陰鬱憂傷」，連彩虹都是灰的！',
      'explain': '🎵 小調 (Minor Scale) = 憂鬱哀傷\n音階結構：全半全全半全全（自然小調），給人哀傷、深沉的感覺。',
      'tag': '調性術語',
    },
    {
      'setup': 'C 大調去聚會最受歡迎，為什麼？',
      'punchline': '因為他「沒有升降記號」，誰都能跟他當朋友！',
      'explain': '🎵 C 大調 (C Major) = 無升降記號\n音階：C-D-E-F-G-A-B-C，鋼琴上全白鍵，最基礎的調性。',
      'tag': '調性術語',
    },
    {
      'setup': '升記號和降記號吵架，誰贏了？',
      'punchline': '沒人贏，因為他們「異名同音」，其實是同一個人！',
      'explain':
          '🎵 異名同音 (Enharmonic) = 音高相同但記譜不同\n例：C# 和 Db 在鋼琴上是同一個鍵，但在樂理上有不同功能。',
      'tag': '調性術語',
    },

    // ===== 和弦術語 (Chords) =====
    {
      'setup': '三和弦去組隊，為什麼最穩定？',
      'punchline': '因為「三個臭皮匠勝過諸葛亮」，根音、三音、五音剛剛好！',
      'explain': '🎵 三和弦 (Triad) = 三音堆疊\n由根音、三度音、五度音組成，是和聲的基本單位（如 C-E-G）。',
      'tag': '和弦術語',
    },
    {
      'setup': '七和弦去夜店，為什麼總是被矚目？',
      'punchline': '因為他多了「第七音」這個神秘色彩，讓氣氛更迷幻！',
      'explain':
          '🎵 七和弦 (Seventh Chord) = 四音堆疊\n在三和弦上加第七音（如 C-E-G-B），增加不穩定感與色彩。',
      'tag': '和弦術語',
    },
    {
      'setup': '屬和弦為什麼像偵探？',
      'punchline': '因為他總是「製造緊張感」，然後帶你回主和弦破案！',
      'explain':
          '🎵 屬和弦 (Dominant Chord) = V 級和弦\n建立緊張感，強烈需要解決到主和弦（V → I），是終止式的核心。',
      'tag': '和弦術語',
    },
    {
      'setup': '減和弦去鬼屋，為什麼不怕？',
      'punchline': '因為他本身就是「最恐怖的」，鬼都嚇跑了！',
      'explain':
          '🎵 減和弦 (Diminished Chord) = 不穩定和弦\n由兩個小三度堆疊（如 B-D-F），音響緊張、不穩定，常用於恐怖氛圍。',
      'tag': '和弦術語',
    },

    // ===== 節奏術語 (Rhythm) =====
    {
      'setup': 'Syncopation 去跳舞，為什麼大家都跟不上？',
      'punchline': '因為他總是「跟別人錯拍」，明明該踩下去卻空拍！',
      'explain': '🎵 Syncopation = 切分音\n重音落在弱拍或弱位上，打破規律節奏，增加動感與驚喜。',
      'tag': '節奏術語',
    },
    {
      'setup': 'Rubato 開車，為什麼警察不敢抓？',
      'punchline': '因為他速度「彈性自由」，一下快一下慢，測速器都壞了！',
      'explain': '🎵 Rubato = 彈性速度\n義大利文「偷來的時間」，演奏時可自由伸縮速度，增加表情。',
      'tag': '節奏術語',
    },
    {
      'setup': 'Triplet 去吃火鍋，為什麼老闆虧本？',
      'punchline': '因為他「三個人只付兩份錢」，還說這是三連音規則！',
      'explain': '🎵 Triplet = 三連音\n在兩拍內均分為三個音符，記號為 3，打破正常節奏劃分。',
      'tag': '節奏術語',
    },
    {
      'setup': '拍號去算命，為什麼被說「性格分裂」？',
      'punchline': '因為他「上面一個數字管拍數，下面一個管單位」，兩個身份！',
      'explain':
          '🎵 拍號 (Time Signature) = 節奏框架\n如 4/4，上方 4 表示每小節 4 拍，下方 4 表示以四分音符為一拍。',
      'tag': '節奏術語',
    },

    // ===== 演奏技巧 (Techniques) =====
    {
      'setup': 'Staccato 說話，為什麼像機關槍？',
      'punchline': '因為他每個字都「短促斷開」，聽起來像連珠炮！',
      'explain': '🎵 Staccato = 斷奏\n記號為音符上加點 (•)，演奏時要短促分離，不連貫。',
      'tag': '演奏技巧',
    },
    {
      'setup': 'Legato 講話，為什麼像唱歌？',
      'punchline': '因為他的字「滑順連貫」，像在唱歌劇！',
      'explain': '🎵 Legato = 連奏\n記號為弧線（圓滑線），演奏時要平滑連接，不中斷。',
      'tag': '演奏技巧',
    },
    {
      'setup': 'Pizzicato 去理髮，為什麼理髮師嚇到？',
      'punchline': '因為他說「我要撥弦式剪髮」，一根一根拔！',
      'explain': '🎵 Pizzicato = 撥弦\n弦樂器用手指撥弦而非用弓，記號 pizz.，產生短促音色。',
      'tag': '演奏技巧',
    },
    {
      'setup': 'Tremolo 去跑馬拉松，為什麼腿抽筋？',
      'punchline': '因為他「快速震音」跑法，腿都變成震動棒了！',
      'explain': '🎵 Tremolo = 震音\n快速重複同一音或兩音交替，如弦樂快速來回運弓，產生顫動效果。',
      'tag': '演奏技巧',
    },
    {
      'setup': 'Glissando 溜滑梯，為什麼摔得最慘？',
      'punchline': '因為他「滑音」一路到底，完全剎不住！',
      'explain': '🎵 Glissando = 滑音\n從一音滑到另一音，經過中間所有音高，常用於鋼琴、豎琴、長號。',
      'tag': '演奏技巧',
    },

    // ===== 曲式術語 (Form) =====
    {
      'setup': 'Rondo 去講故事，為什麼大家都煩？',
      'punchline': '因為他「主題一直重複」，像跳針唱片！',
      'explain': '🎵 Rondo = 輪旋曲式\n結構：A-B-A-C-A...，主題 A 反覆出現，穿插不同段落。',
      'tag': '曲式術語',
    },
    {
      'setup': 'Sonata 寫報告，為什麼教授給滿分？',
      'punchline': '因為他「呈示、發展、再現」三段論述完美！',
      'explain': '🎵 Sonata Form = 奏鳴曲式\n結構：呈示部（主題）→ 發展部（變化）→ 再現部（回歸），古典樂核心曲式。',
      'tag': '曲式術語',
    },
    {
      'setup': 'Canon 去唱歌，為什麼要排隊？',
      'punchline': '因為他是「輪唱」，一個人唱完下一個才能接！',
      'explain': '🎵 Canon = 卡農\n聲部以相同旋律依次進入，形成模仿對位，如《帕海貝爾卡農》。',
      'tag': '曲式術語',
    },
    {
      'setup': 'Theme and Variations 去變裝派對，為什麼得第一？',
      'punchline': '因為他「主題不變但造型百變」，評審看到眼花！',
      'explain': '🎵 主題與變奏 (Theme and Variations)\n先呈示主題，後面用不同手法變化（速度、調性、節奏等）。',
      'tag': '曲式術語',
    },

    // ===== 音程術語 (Intervals) =====
    {
      'setup': '完全五度去健身房，為什麼教練稱讚？',
      'punchline': '因為他「和諧穩定」，肌肉線條完美對稱！',
      'explain': '🎵 完全五度 (Perfect Fifth) = 7 個半音\n如 C-G，音程協和度最高之一，是和聲基礎。',
      'tag': '音程術語',
    },
    {
      'setup': '小二度去吵架，為什麼最吵？',
      'punchline': '因為他「只差半音」，超級刺耳又緊張！',
      'explain': '🎵 小二度 (Minor Second) = 1 個半音\n如 C-Db，是最不協和的音程，製造緊張感。',
      'tag': '音程術語',
    },
    {
      'setup': '八度音程去照鏡子，看到什麼？',
      'punchline': '看到「另一個自己」，只是高低不同！',
      'explain': '🎵 八度 (Octave) = 12 個半音\n如 C-C，同名音但頻率加倍，聽感相同但音高不同。',
      'tag': '音程術語',
    },
    {
      'setup': '增四度為什麼被稱為「魔鬼音程」？',
      'punchline': '因為他在中世紀被禁用，據說「會召喚惡魔」！',
      'explain':
          '🎵 增四度 (Tritone) = 6 個半音\n如 C-F#，極不協和，中世紀稱"Diabolus in Musica"（音樂中的惡魔）。',
      'tag': '音程術語',
    },

    // ===== 音色術語 (Timbre) =====
    {
      'setup': 'Timbre 去選衣服，為什麼店員崩潰？',
      'punchline': '因為他說「我要獨特的質感」，試了 100 件還不滿意！',
      'explain': '🎵 Timbre = 音色\n同音高不同樂器的音質差異，如鋼琴和小提琴的 C 音聽起來不同。',
      'tag': '音色術語',
    },
    {
      'setup': 'Con sordino 去派對，為什麼都沒人理他？',
      'punchline': '因為他裝了「弱音器」，聲音小到像蚊子叫！',
      'explain': '🎵 Con sordino = 加弱音器\n弦樂或銅管加裝弱音器，使音色柔和、音量減弱。',
      'tag': '音色術語',
    },
    {
      'setup': 'Vibrato 說話，為什麼像在顫抖？',
      'punchline': '因為他的聲音「上下波動」，像在冷風中發抖！',
      'explain': '🎵 Vibrato = 顫音\n音高微幅週期性波動，增加音色溫暖度與表情，常見於弦樂、聲樂。',
      'tag': '音色術語',
    },

    // ===== 記譜術語 (Notation) =====
    {
      'setup': '五線譜去看醫生，為什麼醫生說沒救？',
      'punchline': '因為他「上下都長滿音符」，密集恐懼症發作！',
      'explain': '🎵 五線譜 (Staff) = 五條平行橫線\n用於記錄音高位置，線與間共 9 個位置，加上加線可記錄更多音。',
      'tag': '記譜術語',
    },
    {
      'setup': '譜號先生為什麼總是站在最前面？',
      'punchline': '因為他要「確定音高位置」，不然大家都迷路！',
      'explain': '🎵 譜號 (Clef) = 確定音高基準\n如高音譜號（G 譜號）、低音譜號（F 譜號），決定五線譜上的音高。',
      'tag': '記譜術語',
    },
    {
      'setup': '小節線去當警察，為什麼很稱職？',
      'punchline': '因為他「維持秩序」，把音符一段一段分好！',
      'explain': '🎵 小節線 (Bar Line) = 節奏分隔線\n將五線譜分成小節，幫助演奏者掌握節奏與拍號。',
      'tag': '記譜術語',
    },
    {
      'setup': '調號為什麼像身份證？',
      'punchline': '因為他「標示你是哪一調」，升降記號一看就知道！',
      'explain':
          '🎵 調號 (Key Signature) = 調性標記\n寫在譜號後，標示該曲升降音，如一個升記號 = G 大調或 E 小調。',
      'tag': '記譜術語',
    },

    // ===== 表情術語 (Expression) =====
    {
      'setup': 'Dolce 送禮物，為什麼大家都感動？',
      'punchline': '因為他的禮物「甜美溫柔」，連包裝紙都是粉紅色！',
      'explain': '🎵 Dolce = 甜美地\n義大利文「甜」，指示演奏要溫柔甜美，充滿柔情。',
      'tag': '表情術語',
    },
    {
      'setup': 'Espressivo 演講，為什麼台下都哭了？',
      'punchline': '因為他「充滿表情」，連念電話簿都像在朗誦詩歌！',
      'explain': '🎵 Espressivo = 富有表情地\n要求演奏者投入情感，展現音樂的情緒與內涵。',
      'tag': '表情術語',
    },
    {
      'setup': 'Maestoso 走路，為什麼像國王？',
      'punchline': '因為他「莊嚴宏偉」，走三步就要停下來揮手！',
      'explain': '🎵 Maestoso = 莊嚴宏偉地\n義大利文「雄偉」，演奏要展現莊嚴、宏大的氣勢。',
      'tag': '表情術語',
    },
    {
      'setup': 'Giocoso 去上班，為什麼老闆說他不專業？',
      'punchline': '因為他「嬉戲玩鬧」，連開會都在講笑話！',
      'explain': '🎵 Giocoso = 嬉戲地\n義大利文「玩耍」，演奏要輕鬆活潑、充滿趣味。',
      'tag': '表情術語',
    },

    // ===== 和聲術語 (Harmony) =====
    {
      'setup': '協和音程去聯誼，為什麼最受歡迎？',
      'punchline': '因為他「和諧不刺耳」，誰都想跟他當朋友！',
      'explain': '🎵 協和音程 (Consonance)\n聽起來和諧穩定的音程，如完全五度、大小三度。',
      'tag': '和聲術語',
    },
    {
      'setup': '不協和音程去聯誼，為什麼被趕出去？',
      'punchline': '因為他「製造緊張感」，講話都像在吵架！',
      'explain': '🎵 不協和音程 (Dissonance)\n聽起來緊張不穩定的音程，如小二度、增四度，需要解決到協和音程。',
      'tag': '和聲術語',
    },
    {
      'setup': '終止式為什麼像句號？',
      'punchline': '因為他「結束樂句」，讓音樂可以喘口氣！',
      'explain': '🎵 終止式 (Cadence) = 樂句結束公式\n如正格終止（V-I）、變格終止（IV-I），標示段落結束。',
      'tag': '和聲術語',
    },
    {
      'setup': '掛留音為什麼像欠債不還？',
      'punchline': '因為他「延遲解決」，明明該消失卻賴著不走！',
      'explain': '🎵 掛留音 (Suspension)\n前一和弦音延續到下一和弦，造成不協和，最後解決到協和音。',
      'tag': '和聲術語',
    },

    // ===== 樂器術語 (Instruments) =====
    {
      'setup': 'Pizzicato 去按摩，為什麼師傅說他很特別？',
      'punchline': '因為他要求「撥弦式按摩」，一根筋一根筋彈！',
      'explain': '🎵 Pizzicato = 撥弦（重述加深）\n記號 pizz.，弦樂用手指撥弦，產生短促跳躍音色。',
      'tag': '樂器術語',
    },
    {
      'setup': 'Arco 回來上班，為什麼同事歡迎？',
      'punchline': '因為終於「用弓拉奏」，不用再撥弦了！',
      'explain': '🎵 Arco = 用弓拉奏\n弦樂恢復用弓演奏的指示，與 pizzicato 相對。',
      'tag': '樂器術語',
    },
    {
      'setup': 'Pedal 開車，為什麼音樂老師說他很懂？',
      'punchline': '因為他知道「踩踏板可以延長聲音」，就像鋼琴延音踏板！',
      'explain': '🎵 Pedal = 踏板（鋼琴）\n右踏板（延音）、左踏板（弱音）、中踏板（持續音），改變音色與共鳴。',
      'tag': '樂器術語',
    },

    // ===== 節拍術語 (Meter) =====
    {
      'setup': '4/4 拍號為什麼最常見？',
      'punchline': '因為他「穩定好走」，像人類左右腳的步伐！',
      'explain':
          '🎵 4/4 拍號 (Common Time)\n每小節 4 拍，以四分音符為一拍，也稱 C 拍（Common Time）。',
      'tag': '節拍術語',
    },
    {
      'setup': '3/4 拍號去跳舞，為什麼最優雅？',
      'punchline': '因為他是「華爾滋舞步」，一二三、一二三轉圈圈！',
      'explain': '🎵 3/4 拍號 (Waltz Time)\n每小節 3 拍，常用於華爾滋舞曲，給人優雅旋轉感。',
      'tag': '節拍術語',
    },
    {
      'setup': '6/8 拍號為什麼像搖籃？',
      'punchline': '因為他「複合拍子」搖晃感，像在哄嬰兒睡覺！',
      'explain':
          '🎵 6/8 拍號 (Compound Meter)\n每小節 6 拍，但通常感受為 2 大拍（每拍 3 個八分音符），搖擺感強。',
      'tag': '節拍術語',
    },
    {
      'setup': '5/4 拍號走路，為什麼常跌倒？',
      'punchline': '因為他「不規則拍子」，左腳還沒落地右腳就要出發！',
      'explain':
          '🎵 5/4 拍號 (Irregular Meter)\n非對稱拍號（如 2+3 或 3+2），製造不穩定、前衛感，如《碟中諜》主題曲。',
      'tag': '節拍術語',
    },

    // ===== 轉調術語 (Modulation) =====
    {
      'setup': '轉調為什麼像搬家？',
      'punchline': '因為「換了調性」，音樂住到新家了！',
      'explain': '🎵 轉調 (Modulation)\n樂曲中從一個調性轉換到另一個調性，增加色彩變化與發展。',
      'tag': '轉調術語',
    },
    {
      'setup': '屬調轉調為什麼最順暢？',
      'punchline': '因為他「只差一個升降記號」，像搬到隔壁鄰居家！',
      'explain':
          '🎵 屬調轉調 (Dominant Modulation)\n轉到原調的五度上方調性，如 C 大調轉 G 大調，最自然的轉調方式。',
      'tag': '轉調術語',
    },
    {
      'setup': '關係小調為什麼像雙胞胎？',
      'punchline': '因為他們「共用調號」，但一個笑一個哭！',
      'explain': '🎵 關係小調 (Relative Minor)\n與大調共用調號但音階不同，如 C 大調與 A 小調，氣質完全不同。',
      'tag': '轉調術語',
    },

    // ===== 對位術語 (Counterpoint) =====
    {
      'setup': '對位法去談戀愛，為什麼最和諧？',
      'punchline': '因為他知道「兩條旋律要互相獨立又和諧」！',
      'explain': '🎵 對位法 (Counterpoint)\n兩條或多條獨立旋律同時進行，既獨立又和諧，如巴赫賦格。',
      'tag': '對位術語',
    },
    {
      'setup': '賦格為什麼像接力賽？',
      'punchline': '因為「主題輪流進入」，一個聲部追著另一個跑！',
      'explain': '🎵 賦格 (Fugue)\n主題依次在不同聲部進入，形成模仿對位，結構嚴謹複雜。',
      'tag': '對位術語',
    },

    // ===== 裝飾音術語 (Ornaments) =====
    {
      'setup': '顫音為什麼像抖音網紅？',
      'punchline': '因為他「上下快速抖動」，停不下來！',
      'explain': '🎵 顫音 (Trill) = tr\n主音與上方二度音快速交替，增加華麗感。',
      'tag': '裝飾音',
    },
    {
      'setup': '倚音為什麼像小跟班？',
      'punchline': '因為他「緊貼在主音旁邊」，形影不離！',
      'explain': '🎵 倚音 (Appoggiatura)\n裝飾音緊接主音前，佔用主音時值，增加表情。',
      'tag': '裝飾音',
    },
    {
      'setup': '迴音為什麼像繞圈圈？',
      'punchline': '因為他「上下鄰音繞一圈」，才回到主音！',
      'explain': '🎵 迴音 (Turn)\n主音 → 上鄰音 → 主音 → 下鄰音 → 主音，記號 ∞。',
      'tag': '裝飾音',
    },

    // ===== 音樂風格術語 (Styles) =====
    {
      'setup': '巴洛克音樂為什麼像雕花蛋糕？',
      'punchline': '因為「裝飾音超多」，華麗到眼花撩亂！',
      'explain': '🎵 巴洛克 (Baroque 1600-1750)\n特色：華麗裝飾、對比強烈、數字低音，代表：巴赫、韋瓦第。',
      'tag': '音樂風格',
    },
    {
      'setup': '古典樂派為什麼像建築師？',
      'punchline': '因為「結構對稱平衡」，像完美的建築設計！',
      'explain': '🎵 古典樂派 (Classical 1750-1820)\n特色：形式清晰、旋律優美、和聲簡潔，代表：莫札特、海頓。',
      'tag': '音樂風格',
    },
    {
      'setup': '浪漫樂派為什麼像文青？',
      'punchline': '因為「情感豐富」，寫個音符都要附上三頁日記！',
      'explain': '🎵 浪漫樂派 (Romantic 1820-1900)\n特色：情感表達、個人風格、標題音樂，代表：蕭邦、李斯特。',
      'tag': '音樂風格',
    },

    // ===== 進階節奏術語 =====
    {
      'setup': 'Polyrhythm 開車，為什麼警察攔不住？',
      'punchline': '因為他「同時用兩種節奏」，一隻腳踩油門另一隻踩煞車！',
      'explain': '🎵 Polyrhythm = 複節奏\n同時使用兩種或以上不同節奏型態，如 3 對 2（三連音對二分音）。',
      'tag': '進階節奏',
    },
    {
      'setup': 'Hemiola 為什麼像變色龍？',
      'punchline': '因為他「2 拍變 3 拍」，節奏感覺完全變了！',
      'explain':
          '🎵 Hemiola = 3:2 節奏比\n在 6/8 拍中製造 3/4 拍的錯覺，如 6 個八分音符重組為 3 個四分音符。',
      'tag': '進階節奏',
    },
  ];

  /// 重新洗牌
  void _reshuffle() {
    _shuffledIndices = List<int>.generate(_jokes.length, (i) => i)
      ..shuffle(_random);
    _cursor = 0;
    debugPrint('🎲 冷笑話已重新洗牌（共 ${_jokes.length} 則）');
  }

  /// 獲取下一個笑話（避免短時間重複）
  Map<String, String> getNextJoke() {
    if (_shuffledIndices.isEmpty || _cursor >= _shuffledIndices.length) {
      _reshuffle();
    }
    final index = _shuffledIndices[_cursor];
    _cursor++;
    return _jokes[index];
  }

  /// 獲取笑話總數
  int get totalJokes => _jokes.length;

  /// 獲取當前進度（已看過幾個）
  int get currentProgress => _cursor;
}
