// lib/services/joke_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 冷笑話服務 - 提供本地化、附解釋的繁體中文音樂相關冷笑話
class JokeService {
  static final JokeService _instance = JokeService._internal();
  factory JokeService() => _instance;
  JokeService._internal();

  final Random _random = Random();

  // 以洗牌序列避免短時間重複
  List<int> _shuffledIndices = [];
  int _cursor = 0;

  /// 附解釋的冷笑話庫 (繁體中文)
  /// 每筆包含：setup、punchline、explain、tag
  final List<Map<String, String>> _jokes = [
    {
      'setup': '指揮家去夜市最討厭什麼？',
      'punchline': '被喊「不用揮啦，內用外帶？」',
      'explain': '「揮」和「點餐」雙關，指揮家不用揮動指揮棒。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼鋼琴家露營會被趕出去？',
      'punchline': '因為半夜還在找「C音」（洗衣）間。',
      'explain': '「C音」諧音「洗衣」，半夜找洗衣間太吵。',
      'tag': '音樂梗',
    },
    {
      'setup': '爵士鋼琴手喝拿鐵要什麼奶？',
      'punchline': '「替拍」奶。',
      'explain': '「替拍」諧音「替換的拍子」，也像「替換牛奶」。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼鼓手出門都帶雨衣？',
      'punchline': '因為怕被說「你又在亂打雷」。',
      'explain': '鼓聲像打雷，鼓手背鍋。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '小提琴手買兩顆蘋果，為什麼？',
      'punchline': '一顆當「高音」，一顆「低一點」。',
      'explain': '提琴分高音、中低音，買蘋果也要分層。',
      'tag': '樂器梗',
    },
    {
      'setup': '錄音師最怕聽到哪一句？',
      'punchline': '「剛剛那個感覺很好，再錄一次一模一樣。」',
      'explain': '臨場演出難完美複製，錄音師的夢魘。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼薩克斯風手考試總是遲到？',
      'punchline': '因為老師說「先熱身，再吹來」。',
      'explain': '「吹來」諧音「出來」，熱身太久就遲到了。',
      'tag': '樂器梗',
    },
    {
      'setup': '作曲家跟朋友說「回頭再寫信」，結果呢？',
      'punchline': '朋友收到一整本「回頭語（Reprise）」',
      'explain': 'Reprise 是樂段重現，像回頭再說一次。',
      'tag': '和聲梗',
    },
    {
      'setup': '貝斯手為什麼總是站最後面？',
      'punchline': '因為低音就像地基，太前面會被絆到。',
      'explain': '低音支撐和聲，站後面當地基。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼長號手很少去露營？',
      'punchline': '因為「伸縮自如」的帳篷很貴。',
      'explain': '長號的滑管像伸縮帳篷。',
      'tag': '樂器梗',
    },
    {
      'setup': '古典樂手約會最常說什麼？',
      'punchline': '「我們慢板開始，最後來個熱情的快板。」',
      'explain': '樂章常有慢板到快板的對比，套用在約會行程。',
      'tag': '生活梗',
    },
    {
      'setup': '鋼琴黑鍵對白鍵說什麼情話？',
      'punchline': '「沒有我，你的情歌都會少一味。」',
      'explain': '黑鍵補充調式色彩，白鍵情歌需要黑鍵點綴。',
      'tag': '音樂梗',
    },
    {
      'setup': '為什麼合唱團很難開會？',
      'punchline': '大家都在找「共識（共鳴）」',
      'explain': '合唱要共鳴、對齊共識，雙關。',
      'tag': '合唱梗',
    },
    {
      'setup': '貝多芬要是有智慧音箱，會怎樣？',
      'punchline': '他會把提示音關掉，因為「別吵我要寫交響曲」。',
      'explain': '貝多芬耳背、脾氣拗，智慧音箱提示音會惹怒他。',
      'tag': '歷史梗',
    },
    {
      'setup': '為什麼烏克麗麗手不怕忘詞？',
      'punchline': '因為四條弦像便利貼，隨時貼心提醒。',
      'explain': '烏克麗麗弦少，容易邊彈邊記歌。',
      'tag': '樂器梗',
    },
    {
      'setup': '練團遲到的藉口排行榜第一名？',
      'punchline': '「路上遇到 7/8 拍，走兩步就踉蹌。」',
      'explain': '7/8 拍節奏不均勻，拿來當遲到藉口。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼低音提琴手很會搬家？',
      'punchline': '因為每天都在跟巨型家具相處。',
      'explain': '低音提琴體積大，搬運就是日常。',
      'tag': '樂器梗',
    },
    {
      'setup': '鋼琴調音師的生日願望？',
      'punchline': '全世界都 440Hz，別再有人說「我覺得 442 比較甜」',
      'explain': 'A4 標準 440Hz，但也有人喜歡 442Hz。',
      'tag': '音準梗',
    },
    {
      'setup': '電吉他手最害怕什麼節日？',
      'punchline': '停電日。',
      'explain': '電吉他得插電，停電就變觀眾。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼薩克斯風跟長笛分手？',
      'punchline': '因為對方老說「你太銅牽了」。',
      'explain': '薩克斯風是銅管，諧音「同情」。',
      'tag': '樂器梗',
    },
    {
      'setup': '鋼琴家的夢魘是什麼？',
      'punchline': '鄰居按電鈴喊「你又彈錯段落了」。',
      'explain': '鄰居也熟曲子，當場點評。',
      'tag': '舞台日常',
    },
    {
      'setup': '小號手最怕的禁忌詞？',
      'punchline': '「消音」兩個字。',
      'explain': '弱音器裝上去，音量和存在感都被限制。',
      'tag': '樂器梗',
    },
    {
      'setup': '爵士鼓手聊天最愛開場？',
      'punchline': '「你會數到四嗎？」',
      'explain': '爵士鼓常常 1-2-3-4 點歌開始。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼錄音室不放時鐘？',
      'punchline': '因為工程師覺得永遠「需要再錄一 take」。',
      'explain': '錄音講求完美，時間會被忽略。',
      'tag': '錄音室',
    },
    {
      'setup': '長笛手最怕下雨天？',
      'punchline': '因為水氣會讓氣音全跑掉。',
      'explain': '濕氣影響氣流與聲音乾淨度。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼大提琴家喜歡坐著？',
      'punchline': '站著會被誤認搬家公司。',
      'explain': '大提琴大又像家具，搬運感十足。',
      'tag': '樂器梗',
    },
    {
      'setup': '調音師最喜歡的數字？',
      'punchline': '440。',
      'explain': '標準音 A4=440Hz。',
      'tag': '音準梗',
    },
    {
      'setup': '為什麼合唱團不玩狼人殺？',
      'punchline': '因為大家都在練「和聲」，不想吵架。',
      'explain': '合唱講求和諧，不想破壞氣氛。',
      'tag': '合唱梗',
    },
    {
      'setup': '鋼琴老師最怕學生說什麼？',
      'punchline': '「我回家都在想指法，不小心又改了。」',
      'explain': '指法改動會讓肌肉記憶打亂。',
      'tag': '教學梗',
    },
    {
      'setup': '為什麼打擊樂手考駕照很強？',
      'punchline': '因為節奏感好，會「踩點」。',
      'explain': '踩點雙關踩煞車與節奏。',
      'tag': '節奏梗',
    },
    {
      'setup': '薩克斯風手的口頭禪？',
      'punchline': '「我先溫一下簧片。」',
      'explain': '簧片要先濕潤才能發聲穩定。',
      'tag': '樂器梗',
    },
    {
      'setup': '木吉他手怕沒帶什麼？',
      'punchline': '變調夾，沒有就唱不回原 key。',
      'explain': 'Capo 方便轉調伴奏。',
      'tag': '樂器梗',
    },
    {
      'setup': '指揮家最怕什麼天氣？',
      'punchline': '颱風天，因為全團都「跑拍」。',
      'explain': '颱風有風，跑拍是節奏亂掉。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼鋼琴家拒絕海邊婚禮？',
      'punchline': '鹽分太重，琴弦會生鏽。',
      'explain': '海風潮濕易腐蝕金屬弦。',
      'tag': '樂器梗',
    },
    {
      'setup': '電子琴手最怕什麼按鈕？',
      'punchline': 'Demo 鍵被誤按。',
      'explain': '示範曲放出來像是「假彈」。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼爵士樂手常戴帽子？',
      'punchline': '因為帽沿遮住他們在算拍的表情。',
      'explain': '即興時心算節奏，表情專注。',
      'tag': '節奏梗',
    },
    {
      'setup': '貝斯手的求生三寶？',
      'punchline': '調音器、DI 盒、跟拍器。',
      'explain': '穩定音準、輸出與節拍是低音基礎。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼合聲常比主唱早一步來？',
      'punchline': '因為要先找到共鳴點。',
      'explain': '共鳴需要位置，先進來抓和聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '長號手的伸縮管掉了怎麼辦？',
      'punchline': '改吹口風琴，至少還能滑音。',
      'explain': '口風琴滑音有限，開玩笑的。',
      'tag': '樂器梗',
    },
    {
      'setup': '烏克麗麗手進錄音室最怕什麼？',
      'punchline': '工程師說「可以彈分解和弦」',
      'explain': '分解和弦一錄就暴露手指噪音。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼鋼琴家帶兩支鉛筆？',
      'punchline': '一支圈指法，一支擦掉改過的指法。',
      'explain': '指法常微調，需要寫寫擦擦。',
      'tag': '教學梗',
    },
    {
      'setup': '電吉他手最怕遇到什麼工程？',
      'punchline': '音響師說「請乾聲」',
      'explain': '乾聲沒效果器，很赤裸。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼合唱指揮常比心？',
      'punchline': '因為要提醒「氣息要一起」。',
      'explain': '比心形像吸氣手勢。',
      'tag': '合唱梗',
    },
    {
      'setup': '鼓手面試常被問什麼？',
      'punchline': '「你會跟節拍器嗎？」',
      'explain': '鼓是節奏核心，能否跟點是關鍵。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼錄音師都愛黑咖啡？',
      'punchline': '因為奶泡聲會被麥克風收進去。',
      'explain': '拉奶泡的噪音會干擾錄音。',
      'tag': '錄音室',
    },
    {
      'setup': '薩克斯風手跟鋼琴手吵架，誰會贏？',
      'punchline': '鋼琴手，因為他有 88 個「鍵」盤。',
      'explain': '鍵盤=鍵，雙關「籌碼」。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼管樂團午餐都吃清淡？',
      'punchline': '怕油膩影響口風。',
      'explain': '嘴唇油膩會滑，控制差。',
      'tag': '舞台日常',
    },
    {
      'setup': '木管手最討厭的禮物？',
      'punchline': '糖果棒。',
      'explain': '糖分讓簧片變黏，發音跑掉。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼鼓手的朋友最誠實？',
      'punchline': '因為每次排練都在「實話實說」四拍。',
      'explain': '四拍穩定，比喻直接。',
      'tag': '節奏梗',
    },
    {
      'setup': '合唱團暖身時路人以為什麼？',
      'punchline': '以為在召喚怪物。',
      'explain': '暖身常有奇怪母音與氣音。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴搬家要四個人？',
      'punchline': '兩個抬琴，兩個負責心碎。',
      'explain': '鋼琴重且易傷，搬運心驚。',
      'tag': '樂器梗',
    },
    {
      'setup': '電子鼓手去野外演出需要什麼？',
      'punchline': '插座比鼓棒更重要。',
      'explain': '電子鼓必須供電。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼指揮拿雙筒望遠鏡？',
      'punchline': '要確定最後排的大提琴有沒有偷滑手機。',
      'explain': '尾排距離遠，開玩笑。',
      'tag': '舞台日常',
    },
    {
      'setup': '爵士樂手排練常說的話？',
      'punchline': '「這裡自由一點。」',
      'explain': '即興風格，結構鬆。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼小號手都備兩個吹嘴？',
      'punchline': '一個表演，一個掉地上時用。',
      'explain': '吹嘴掉了會凹傷，需替換。',
      'tag': '樂器梗',
    },
    {
      'setup': '錄音師最愛哪句台詞？',
      'punchline': '「再來一條保險。」',
      'explain': '多錄 take 以便挑選。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼貝斯手常穿深色衣服？',
      'punchline': '因為他們習慣在舞台邊緣當影子英雄。',
      'explain': '貝斯常不搶眼，但支撐音樂。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '長笛手喝珍奶要注意什麼？',
      'punchline': '不要卡到簧片——喔對了，他沒有簧片。',
      'explain': '長笛無簧，玩諧音梗。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼鋼琴家的包包超重？',
      'punchline': '裡面裝滿總譜、節拍器和三支筆。',
      'explain': '鋼琴伴奏需帶譜與工具。',
      'tag': '舞台日常',
    },
    {
      'setup': '合唱團員最怕的禮拜天？',
      'punchline': '感冒的禮拜天。',
      'explain': '感冒聲音啞掉，和聲崩潰。',
      'tag': '合唱梗',
    },
    {
      'setup': '爵士鋼琴手跟古典鋼琴手吵架，誰先讓步？',
      'punchline': '古典鋼琴手，因為他先看到「pp」。',
      'explain': 'pp 是極弱音記號，雙關「讓步」。',
      'tag': '音樂梗',
    },
    {
      'setup': '為什麼提琴手拿膠水？',
      'punchline': '鬆弓毛時可以黏回——開玩笑的，請找專業。',
      'explain': '弓毛掉了要換，不是黏。',
      'tag': '樂器梗',
    },
    {
      'setup': '低音號手面試常被問？',
      'punchline': '「你能小聲一點嗎？」',
      'explain': '低音號共鳴大，音量控制重要。',
      'tag': '樂器梗',
    },
    {
      'setup': '鋼琴調音師最怕聽到哪首曲子？',
      'punchline': '人人彈「給愛麗絲」。',
      'explain': '新手常彈，錯音多，調完又走音。',
      'tag': '音準梗',
    },
    {
      'setup': '打擊樂手的行李箱裝什麼？',
      'punchline': '半個五金行。',
      'explain': '各種器材配件、鼓鎖、螺絲、膠帶。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼鋼琴黑鍵個性好？',
      'punchline': '因為它們總是在「間」裡，懂得留空。',
      'explain': '黑鍵在白鍵間，留白幽默。',
      'tag': '音樂梗',
    },
    {
      'setup': '合唱團暖身拉音階像什麼？',
      'punchline': '像貓咪打哈欠的大合奏。',
      'explain': '暖身母音延長，像哈欠聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鼓手不愛用玻璃杯？',
      'punchline': '怕情緒來了直接「Crash」掉。',
      'explain': 'Crash 是碎音鈸，雙關打碎。',
      'tag': '節奏梗',
    },
    {
      'setup': '貝斯手被要求獨奏時會說什麼？',
      'punchline': '「可以先關燈嗎？」',
      'explain': '貝斯手習慣低調，開玩笑。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼管風琴師很少搬家？',
      'punchline': '因為風琴搬不走，只能換工作。',
      'explain': '管風琴巨大裝在場地。',
      'tag': '樂器梗',
    },
    {
      'setup': '爵士樂手問鼓手「你自由嗎？」意思是？',
      'punchline': '不是約你，是想要自由拍子。',
      'explain': '自由拍即興，非約會。',
      'tag': '節奏梗',
    },
    {
      'setup': '鋼琴家旅行必備什麼？',
      'punchline': '矽膠指套，比護照還怕忘。',
      'explain': '保護手指避免受傷。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼吉他手喜歡開車兜風？',
      'punchline': '可以練習四拍點頭。',
      'explain': '點頭踩節奏，幽默。',
      'tag': '節奏梗',
    },
    {
      'setup': '錄音室貼滿「安靜」標語的原因？',
      'punchline': '因為任何塑膠袋聲音都比你的和聲清楚。',
      'explain': '麥克風會放大細碎噪音。',
      'tag': '錄音室',
    },
    {
      'setup': '小號手覺得冬天最棒的事？',
      'punchline': '金屬管子冰到讓你自帶冷音色。',
      'explain': '低溫讓音色偏冷，玩笑。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼鋼琴家不怕停電？',
      'punchline': '因為他本來就用聲音點亮全場。',
      'explain': '鋼琴是原聲樂器，無需電。',
      'tag': '生活梗',
    },
    {
      'setup': '合唱團排練最怕的動物是？',
      'punchline': '青蛙，因為一直「呱」插拍子。',
      'explain': '呱聲干擾節奏。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼打擊樂手愛用膠帶？',
      'punchline': '因為人生沒有什麼是膠帶解決不了的。',
      'explain': '鼓皮、固定、標記都靠膠帶。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '爵士鋼琴手看到「4/4」會說什麼？',
      'punchline': '「好吧，我試著乖一點。」',
      'explain': '爵士常玩變拍，4/4 顯得乖。',
      'tag': '節奏梗',
    },
    {
      'setup': '薩克斯風手最喜歡哪種口罩？',
      'punchline': '能開口的。',
      'explain': '演出要吹氣，口罩要方便。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼弦樂手不喜歡下樓梯？',
      'punchline': '怕滑弓，連帶滑倒。',
      'explain': '滑弓與滑倒雙關。',
      'tag': '樂器梗',
    },
    {
      'setup': '錄音師半夜夢到什麼最可怕？',
      'punchline': 'Limiter 爆紅燈。',
      'explain': '爆音失真會毀錄音。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼和聲老師常說「呼吸一起」？',
      'punchline': '因為沒有一起呼吸，和聲就像不同語言。',
      'explain': '呼吸同步讓發聲一致。',
      'tag': '合唱梗',
    },
    {
      'setup': '長號手最怕的考試題？',
      'punchline': '「請用滑管畫出心形。」',
      'explain': '滑管有限行程，畫不出。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼鋼琴家上健身房？',
      'punchline': '為了搬琴的時候不被笑。',
      'explain': '鋼琴重，體力很重要。',
      'tag': '舞台日常',
    },
    {
      'setup': '電子樂手出門帶兩個行李箱？',
      'punchline': '一個放衣服，一個放線材。',
      'explain': '電子設備線材多。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼節奏吉他手總是笑？',
      'punchline': '因為他知道大家會跟著他的「刷刷刷」。',
      'explain': '節奏吉他主導 groove。',
      'tag': '節奏梗',
    },
    {
      'setup': '貝斯手收到什麼訊息會慌？',
      'punchline': '「今天不用貝斯，改用合成器低音。」',
      'explain': '低音被取代的恐慌。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼鋼琴家不怕沒座位？',
      'punchline': '因為他自帶椅子（琴凳）。',
      'explain': '演出琴凳必備。',
      'tag': '生活梗',
    },
    {
      'setup': '錄音室禁止穿什麼鞋？',
      'punchline': '拖鞋，腳步聲會被收。',
      'explain': '拖鞋拍打地面聲顯著。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼合唱團愛喝溫水？',
      'punchline': '因為冰水會讓高音變「冰」。',
      'explain': '冷水讓喉嚨緊繃。',
      'tag': '合唱梗',
    },
    {
      'setup': '爵士鼓手遲到時會說？',
      'punchline': '「路上塞 5/4 拍。」',
      'explain': '5/4 拍不平均，當藉口。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼中提琴手常被開玩笑？',
      'punchline': '因為大家都忘了他在中間很重要。',
      'explain': '中提琴支撐中頻卻常被忽略。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '鋼琴家最常 Google 什麼？',
      'punchline': '「附近哪裡有可借琴的場地？」',
      'explain': '鋼琴不好攜帶，需借琴。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼薩克斯風手口袋裡有小螺絲起子？',
      'punchline': '因為隨時要救簧片螺絲。',
      'explain': '簧片卡座需要螺絲固定。',
      'tag': '樂器梗',
    },
    {
      'setup': '合唱團排練聞到蒜味會怎樣？',
      'punchline': '整排高音瞬間變嘶啞。',
      'explain': '蒜味刺激喉嚨，開玩笑。',
      'tag': '合唱梗',
    },
    {
      'setup': '錄音師最怕的動物？',
      'punchline': '蚊子，因為高頻尖到爆表。',
      'explain': '蚊子聲高頻尖銳。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼鍵盤手愛帶延長線？',
      'punchline': '因為沒有電，他就是路人。',
      'explain': '電子鍵盤全靠電力。',
      'tag': '樂器梗',
    },
    {
      'setup': '爵士樂手的 GPS 會說什麼？',
      'punchline': '「前方 4 小節後即興左轉。」',
      'explain': '把路線比喻成樂段。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼大鍵琴手去超市會迷路？',
      'punchline': '因為他找不到「古」典區。',
      'explain': '雙關古典。',
      'tag': '歷史梗',
    },
    {
      'setup': '打擊樂手最怕換什麼鼓皮？',
      'punchline': '低音鼓皮，換完還要搬全場。',
      'explain': '低鼓大又重。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼鋼琴老師喜歡方格筆記本？',
      'punchline': '方便畫小節線。',
      'explain': '格線可對應節拍。',
      'tag': '教學梗',
    },
    {
      'setup': '長笛手吹到頭暈怎麼辦？',
      'punchline': '先休息，再怪空氣不夠好。',
      'explain': '吹氣量大易缺氧，幽默。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼指揮家常閉眼？',
      'punchline': '他在心裡看總譜。',
      'explain': '熟譜到可以腦內播放。',
      'tag': '舞台日常',
    },
    {
      'setup': '電子音樂人最怕的訊息？',
      'punchline': '「你這個 preset 我聽過。」',
      'explain': '預設音色被認出，創意被質疑。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼合唱團排練要關手機？',
      'punchline': '因為「叮咚」比高音更搶戲。',
      'explain': '通知聲干擾和聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '貝斯手買鞋的標準？',
      'punchline': '踩下去要穩，像 1 跟 3 一樣穩。',
      'explain': '低音拍要穩定，鞋也要穩。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼鋼琴家愛戴耳塞？',
      'punchline': '不是嫌你吵，是保護黃金耳。',
      'explain': '長期演出保護聽力。',
      'tag': '舞台日常',
    },
    {
      'setup': '打擊樂手出門忘記帶什麼最慘？',
      'punchline': '鼓鎖，一顆螺絲就能毀演出。',
      'explain': '鼓鎖維護張力。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼鋼琴伴奏薪水難談？',
      'punchline': '因為他們總是說「再彈一次就好」。',
      'explain': '伴奏常被要求多次試彈。',
      'tag': '教學梗',
    },
    {
      'setup': '爵士鼓手的健身方式？',
      'punchline': '單踏＋雙踏當有氧。',
      'explain': '踩踏練習像跑步。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼中提琴手愛講冷笑話？',
      'punchline': '因為他們習慣「中」段突如其來的幽默。',
      'explain': '中提琴常承上啟下。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '錄音師收藏耳機的理由？',
      'punchline': '每支耳機都有不同性格，像不同歌手。',
      'explain': '耳機音色差異大。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼合唱團最怕咖啡拉花？',
      'punchline': '因為拉花聲太大，練不到弱聲部。',
      'explain': '咖啡機蒸汽聲吵。',
      'tag': '合唱梗',
    },
    {
      'setup': '鋼琴家和鼓手交換工作會怎樣？',
      'punchline': '鼓手抱怨沒有 4/4，鋼琴家抱怨沒有蓋子。',
      'explain': '鋼琴有上蓋，鼓沒有；節奏習慣不同。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '為什麼手風琴手冬天很暖？',
      'punchline': '因為風箱就是自帶暖氣。',
      'explain': '推拉風箱像暖風。',
      'tag': '樂器梗',
    },
    {
      'setup': '小號手上飛機最怕什麼？',
      'punchline': '行李艙壓力讓吹嘴鬆脫。',
      'explain': '氣壓變化影響組件。',
      'tag': '舞台日常',
    },
    {
      'setup': '為什麼爵士樂手喜歡深夜？',
      'punchline': '因為節奏在夜裡比較「藍」。',
      'explain': 'Blue 調性，夜晚氣氛。',
      'tag': '節奏梗',
    },
    {
      'setup': '合唱團員感冒時的解法？',
      'punchline': '站最後排假裝低音。',
      'explain': '聲音低啞，只能混低頻。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼電鋼琴手最愛 Pedal？',
      'punchline': '因為沒有延音，心裡不安全。',
      'explain': '踏板帶來持續感。',
      'tag': '樂器梗',
    },
    {
      'setup': '鼓手買耳塞的理由？',
      'punchline': '保護聽力，免得日後聽不到自己的節奏笑話。',
      'explain': '長期大音壓需防護。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼鋼琴家常帶護手霜？',
      'punchline': '鍵盤太乾會「卡手」。',
      'explain': '手指乾裂影響觸鍵。',
      'tag': '舞台日常',
    },
    {
      'setup': '電子鼓手最怕的場地？',
      'punchline': '沒有插座還有 Wi-Fi 密碼。',
      'explain': '沒電就無法演出。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼中提琴譜看起來像外星文？',
      'punchline': '因為中音譜號讓人懷疑人生。',
      'explain': '中音譜號較少見。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '合唱團排練時有人吃餅乾會怎樣？',
      'punchline': '整段都變脆脆的。',
      'explain': '餅乾聲干擾發聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家怕冷氣直吹？',
      'punchline': '手指冰冷，樂句也跟著冰。',
      'explain': '手冷影響觸鍵與音色。',
      'tag': '舞台日常',
    },
    {
      'setup': '爵士樂手的行事曆長什麼樣？',
      'punchline': '滿滿的「可能」和「再看看」。',
      'explain': '即興精神，行程也鬆。',
      'tag': '生活梗',
    },
    {
      'setup': '為什麼指揮家愛黑色西裝？',
      'punchline': '因為要當所有聲部的背景布。',
      'explain': '黑色不搶色。',
      'tag': '舞台日常',
    },
    {
      'setup': '小號手吹完一場最想做什麼？',
      'punchline': '放鬆嘴唇，順便抱怨口水孔。',
      'explain': '長時間吹嘴唇疲勞，還要倒水。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼和聲老師帶節拍器？',
      'punchline': '因為和聲也會「跑拍」。',
      'explain': '節奏不穩會影響和聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '錄音師聽到誰最先皺眉？',
      'punchline': '塑膠袋。',
      'explain': '塑膠袋沙沙聲尖銳。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼鋼琴家不愛戴戒指演出？',
      'punchline': '戒指會敲到鍵盤，變打擊樂。',
      'explain': '金屬聲干擾。',
      'tag': '舞台日常',
    },
    {
      'setup': '合唱團找音準的方法？',
      'punchline': '先找到團員，再找到 440。',
      'explain': '音叉標準音 440Hz。',
      'tag': '音準梗',
    },
    {
      'setup': '為什麼打擊樂手常帶手套？',
      'punchline': '搬樂器時保命，演出時防汗。',
      'explain': '搬運與防滑。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '爵士樂手遲到時的補救？',
      'punchline': 'Solo 多 8 小節算賠罪。',
      'explain': '以演出表現補償。',
      'tag': '生活梗',
    },
    {
      'setup': '為什麼鋼琴家手指甲要剪很短？',
      'punchline': '不然彈琴會變自帶 Castanet。',
      'explain': '指甲敲鍵盤會出聲。',
      'tag': '舞台日常',
    },
    {
      'setup': '貝斯手最愛的度數？',
      'punchline': '五度，因為走五度圈像散步。',
      'explain': '和聲進行常用五度圈。',
      'tag': '和聲梗',
    },
    {
      'setup': '為什麼長笛手練習要先擦管？',
      'punchline': '因為水氣會讓高音變成低氣音。',
      'explain': '水滴影響氣柱振動。',
      'tag': '樂器梗',
    },
    {
      'setup': '錄音師過年最怕什麼聲？',
      'punchline': '鞭炮，連耳機都震到爆。',
      'explain': '大音壓傷耳。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼合唱團練習常做伸展？',
      'punchline': '身體鬆，聲音才會鬆。',
      'explain': '放鬆肌肉助發聲。',
      'tag': '合唱梗',
    },
    {
      'setup': '爵士鼓手的新年願望？',
      'punchline': '鄰居也懂 Odd Meter。',
      'explain': '奇數拍子不易懂，鄰居聽不慣。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼鋼琴家喜歡布面鞋？',
      'punchline': '踩踏板時比較安靜。',
      'explain': '硬底鞋會有敲擊聲。',
      'tag': '舞台日常',
    },
    {
      'setup': '合唱團指揮喊「看我」是在說什麼？',
      'punchline': '不只是看，而是一起呼吸。',
      'explain': '指揮手勢提示呼吸與進拍。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家怕手汗？',
      'punchline': '手汗讓八度變滑梯。',
      'explain': '手滑會失誤。',
      'tag': '舞台日常',
    },
    {
      'setup': '錄音師愛哪種椅子？',
      'punchline': '沒有任何吱吱聲的。',
      'explain': '椅子異音會收進麥克風。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼長號手喜歡滑水道？',
      'punchline': '終於有滑管以外的滑。',
      'explain': '滑水道與滑管雙關。',
      'tag': '樂器梗',
    },
    {
      'setup': '爵士樂手講故事的結尾？',
      'punchline': '「然後我就即興了。」',
      'explain': '即興是習慣。',
      'tag': '生活梗',
    },
    {
      'setup': '為什麼合唱團討厭塑膠椅？',
      'punchline': '坐下去「咯吱」比高音還尖。',
      'explain': '噪音干擾。',
      'tag': '合唱梗',
    },
    {
      'setup': '鋼琴家最愛的 emoji？',
      'punchline': '🎹，因為鍵盤帶著走。',
      'explain': 'emoji 簡單代表身份。',
      'tag': '生活梗',
    },
    {
      'setup': '為什麼打擊樂手愛收集鼓棒？',
      'punchline': '因為每對鼓棒都有不同聲音個性。',
      'explain': '材質重量差異大。',
      'tag': '樂團吐槽',
    },
    {
      'setup': '合唱團講冷笑話的效果？',
      'punchline': '和聲突然變成「哈哈哈」的分解和弦。',
      'explain': '笑聲也會分聲部。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家不喜歡手套彈琴？',
      'punchline': '觸鍵像隔著棉被。',
      'explain': '手感全失。',
      'tag': '舞台日常',
    },
    {
      'setup': '錄音師的新年新希望？',
      'punchline': '今年不要再聽到鄰居裝修。',
      'explain': '工地噪音最怕。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼爵士樂手常說「You feel？」',
      'punchline': '因為 Groove 靠感覺，不靠樂譜。',
      'explain': '即興重感覺。',
      'tag': '節奏梗',
    },
    {
      'setup': '合唱團最怕的手機鈴聲？',
      'punchline': '鬧鐘，因為永遠不在拍上。',
      'explain': '鬧鐘節奏與歌曲無關。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家愛保溫杯？',
      'punchline': '手邊有溫水，音色才不會「冷」。',
      'explain': '喝溫水保喉與手感。',
      'tag': '生活梗',
    },
    {
      'setup': '小提琴家練音階像什麼？',
      'punchline': '像在樓梯跑上下，還要保持優雅。',
      'explain': '音階上下行需均勻音色。',
      'tag': '樂器梗',
    },
    {
      'setup': '為什麼鼓手喜歡數「1 e & a」？',
      'punchline': '因為這樣人生四等份都掌握了。',
      'explain': '16 分音符分拍口訣。',
      'tag': '節奏梗',
    },
    {
      'setup': '合唱團上台前最需要什麼？',
      'punchline': '安靜的呼吸，不是安靜的心跳。',
      'explain': '呼吸控制比心跳重要。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家怕吃麻辣鍋？',
      'punchline': '手指腫了八度變九度。',
      'explain': '辣導致浮腫，玩笑。',
      'tag': '生活梗',
    },
    {
      'setup': '爵士樂手最怕遇到誰？',
      'punchline': '版權管理員，因為和弦走向太自由。',
      'explain': '即興可能碰到旋律版權。',
      'tag': '生活梗',
    },
    {
      'setup': '為什麼錄音師喜歡地毯？',
      'punchline': '腳步聲吸掉，心情也安靜。',
      'explain': '地毯吸音。',
      'tag': '錄音室',
    },
    {
      'setup': '合唱團練習時有人打噴嚏會怎樣？',
      'punchline': '整排跟著走音半拍。',
      'explain': '突然聲響打亂專注。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家喜歡柔焦燈光？',
      'punchline': '因為手汗在強光下會反光。',
      'explain': '強光照到琴鍵與手。',
      'tag': '舞台日常',
    },
    {
      'setup': '爵士鼓手看到 7/8 會說？',
      'punchline': '「好，這趟路會晃一下。」',
      'explain': '奇數拍像不平路。',
      'tag': '節奏梗',
    },
    {
      'setup': '為什麼管弦樂團喜歡調 440 而不是 441？',
      'punchline': '因為少一點爭論，多一點和聲。',
      'explain': '標準化減少爭議。',
      'tag': '音準梗',
    },
    {
      'setup': '合唱團最怕哪種麥克風？',
      'punchline': '會自己唱的 Auto-Tune 麥。',
      'explain': '自動修音像被接管。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家怕亮面指甲油？',
      'punchline': '會在黑鍵上留下「證據」。',
      'explain': '指甲油刮痕顯眼。',
      'tag': '舞台日常',
    },
    {
      'setup': '錄音師最愛的天氣？',
      'punchline': '陰天，因為街上少車聲。',
      'explain': '雨天或陰天戶外噪音較少。',
      'tag': '錄音室',
    },
    {
      'setup': '為什麼爵士樂手愛說「Take it easy」？',
      'punchline': '因為鬆才有 swing。',
      'explain': 'Swing 需要鬆弛感。',
      'tag': '節奏梗',
    },
    {
      'setup': '合唱團開會最常決定什麼？',
      'punchline': '誰帶音叉。',
      'explain': '開場定音重要。',
      'tag': '合唱梗',
    },
    {
      'setup': '為什麼鋼琴家愛擦琴鍵？',
      'punchline': '不只是整潔，也是防滑。',
      'explain': '保持觸感穩定。',
      'tag': '舞台日常',
    },
  ];

  void _reshuffle() {
    _shuffledIndices = List<int>.generate(_jokes.length, (i) => i)
      ..shuffle(_random);
    _cursor = 0;
  }

  /// 取得一則近期不重複的笑話（走訪洗牌序列）
  Map<String, String> getNextJoke() {
    if (_jokes.isEmpty) {
      return {
        'setup': '今天的笑話庫空空的',
        'punchline': '明天再來看看吧！',
        'explain': '暫無資料',
        'tag': '提示',
      };
    }

    if (_shuffledIndices.isEmpty || _cursor >= _shuffledIndices.length) {
      _reshuffle();
    }

    final index = _shuffledIndices[_cursor];
    _cursor++;
    final joke = _jokes[index];
    debugPrint('🎭 JokeService: 獲取笑話 #$index');
    return joke;
  }

  /// 獲取多個不重複的隨機笑話
  List<Map<String, String>> getMultipleJokes(int count) {
    if (_jokes.isEmpty) return [];

    final maxCount = count.clamp(0, _jokes.length);
    final order = List<int>.generate(_jokes.length, (i) => i)..shuffle(_random);
    return order.take(maxCount).map((i) => _jokes[i]).toList();
  }

  /// 獲取笑話總數
  int get totalJokes => _jokes.length;

  /// 獲取特定類別的笑話數量
  Map<String, int> get jokeStats => {
        'total': _jokes.length,
        'music': _jokes
            .where((j) =>
                j['setup']!.contains('音樂') ||
                j['setup']!.contains('鋼琴') ||
                j['setup']!.contains('樂器'))
            .length,
      };
}
