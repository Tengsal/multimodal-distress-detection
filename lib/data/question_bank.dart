import '../models/question.dart';

// ================================================================
//  ADAPTIVE FSM QUESTION BANK
//  100 questions · 6 modules · 20 clinical features
//
//  BRANCHING RULE (per question):
//    1–2  = low severity   → skip to next feature or exit module
//    3    = moderate       → 1–2 follow-up questions
//    4–5  = high severity  → full deep-dive branch
//
//  MODULE FLOW:
//    sleep → mood → anxiety → social → energy → cognitive → end
//
//  20 FEATURES ASSESSED:
//    Sleep    : (1) onset  (2) maintenance  (3) quality  (4) circadian
//    Mood     : (5) depressed mood  (6) anhedonia  (7) hopelessness
//               (8) self-worth/guilt  (9) suicidal ideation
//    Anxiety  : (10) general tension  (11) excessive worry
//               (12) physical symptoms  (13) avoidance
//    Social   : (14) connectedness  (15) withdrawal  (16) interpersonal conflict
//    Energy   : (17) fatigue/energy  (18) appetite/physical wellbeing
//    Cognitive: (19) concentration/focus  (20) decision-making/memory
//
//  EXPECTED SESSION LENGTH:
//    Minimum  (all 1s): ~6 questions
//    Moderate (mixed):  ~20–30 questions
//    Maximum  (all 5s): up to 100 questions
// ================================================================

class QuestionBank {
  static Map<String, Question> questions = {

    // ============================================================
    //  MODULE 1 · SLEEP  (sleep_01–16, 4 features)
    // ============================================================

    // ── Feature 1: Sleep Onset ───────────────────────────────────

    /// ENTRY — general sleep gate
    "sleep_01": Question(
      id: "sleep_01",
      module: "sleep",
      text: "I have been having trouble sleeping.",
      transitions: {
        1: "mood_01",   // no sleep issues → skip module
        2: "mood_01",
        3: "sleep_02",  // some trouble → onset branch
        4: "sleep_02",
        5: "sleep_02",
      },
    ),

    "sleep_02": Question(
      id: "sleep_02",
      module: "sleep",
      text: "I struggle to fall asleep when I first get into bed.",
      transitions: {
        1: "sleep_05",  // onset fine → skip to maintenance
        2: "sleep_05",
        3: "sleep_03",
        4: "sleep_03",
        5: "sleep_03",
      },
    ),

    "sleep_03": Question(
      id: "sleep_03",
      module: "sleep",
      text: "Thoughts race through my mind and prevent me from falling asleep.",
      transitions: {
        1: "sleep_05",
        2: "sleep_05",
        3: "sleep_04",
        4: "sleep_04",
        5: "sleep_04",
      },
    ),

    "sleep_04": Question(
      id: "sleep_04",
      module: "sleep",
      text: "I feel anxious or tense when I get into bed at night.",
      transitions: {
        1: "sleep_05",
        2: "sleep_05",
        3: "sleep_05",
        4: "sleep_05",
        5: "sleep_05",
      },
    ),

    // ── Feature 2: Sleep Maintenance ────────────────────────────

    "sleep_05": Question(
      id: "sleep_05",
      module: "sleep",
      text: "I wake up multiple times during the night.",
      transitions: {
        1: "sleep_09",  // no maintenance issues → skip to quality
        2: "sleep_09",
        3: "sleep_06",
        4: "sleep_06",
        5: "sleep_06",
      },
    ),

    "sleep_06": Question(
      id: "sleep_06",
      module: "sleep",
      text: "I wake up much earlier than I intend to and cannot fall back asleep.",
      transitions: {
        1: "sleep_09",
        2: "sleep_09",
        3: "sleep_07",
        4: "sleep_07",
        5: "sleep_07",
      },
    ),

    "sleep_07": Question(
      id: "sleep_07",
      module: "sleep",
      text: "I have disturbing dreams or nightmares that interrupt my sleep.",
      transitions: {
        1: "sleep_09",
        2: "sleep_09",
        3: "sleep_08",
        4: "sleep_08",
        5: "sleep_08",
      },
    ),

    "sleep_08": Question(
      id: "sleep_08",
      module: "sleep",
      text: "Physical discomfort such as pain or needing to use the bathroom wakes me up.",
      transitions: {
        1: "sleep_09",
        2: "sleep_09",
        3: "sleep_09",
        4: "sleep_09",
        5: "sleep_09",
      },
    ),

    // ── Feature 3: Sleep Quality / Restoration ───────────────────

    "sleep_09": Question(
      id: "sleep_09",
      module: "sleep",
      text: "I feel unrefreshed and tired even after a full night's sleep.",
      transitions: {
        1: "sleep_12",  // good quality → skip to circadian
        2: "sleep_12",
        3: "sleep_10",
        4: "sleep_10",
        5: "sleep_10",
      },
    ),

    "sleep_10": Question(
      id: "sleep_10",
      module: "sleep",
      text: "I experience significant daytime sleepiness that affects my functioning.",
      transitions: {
        1: "sleep_12",
        2: "sleep_12",
        3: "sleep_11",
        4: "sleep_11",
        5: "sleep_11",
      },
    ),

    "sleep_11": Question(
      id: "sleep_11",
      module: "sleep",
      text: "Poor sleep noticeably worsens my mood, patience, or ability to concentrate.",
      transitions: {
        1: "sleep_12",
        2: "sleep_12",
        3: "sleep_12",
        4: "sleep_12",
        5: "sleep_12",
      },
    ),

    // ── Feature 4: Circadian Rhythm / Sleep Schedule ─────────────

    "sleep_12": Question(
      id: "sleep_12",
      module: "sleep",
      text: "My sleep and wake times vary greatly from day to day.",
      transitions: {
        1: "mood_01",   // regular schedule → exit sleep module
        2: "mood_01",
        3: "sleep_13",
        4: "sleep_13",
        5: "sleep_13",
      },
    ),

    "sleep_13": Question(
      id: "sleep_13",
      module: "sleep",
      text: "I often stay up much later than I intend to.",
      transitions: {
        1: "mood_01",
        2: "mood_01",
        3: "sleep_14",
        4: "sleep_14",
        5: "sleep_14",
      },
    ),

    "sleep_14": Question(
      id: "sleep_14",
      module: "sleep",
      text: "I use screens or devices in bed immediately before trying to sleep.",
      transitions: {
        1: "sleep_15",
        2: "sleep_15",
        3: "sleep_15",
        4: "sleep_15",
        5: "sleep_15",
      },
    ),

    "sleep_15": Question(
      id: "sleep_15",
      module: "sleep",
      text: "I use alcohol, medication, or other substances to help me fall asleep.",
      transitions: {
        1: "mood_01",
        2: "mood_01",
        3: "sleep_16",
        4: "sleep_16",
        5: "sleep_16",
      },
    ),

    "sleep_16": Question(
      id: "sleep_16",
      module: "sleep",
      text: "My sleep problems have significantly disrupted my work, relationships, or quality of life.",
      transitions: {
        1: "mood_01",
        2: "mood_01",
        3: "mood_01",
        4: "mood_01",
        5: "mood_01",
      },
    ),

    // ============================================================
    //  MODULE 2 · MOOD  (mood_01–22, 5 features)
    // ============================================================

    // ── Feature 5: Depressed Mood ────────────────────────────────

    /// ENTRY — general mood gate
    "mood_01": Question(
      id: "mood_01",
      module: "mood",
      text: "I have been feeling persistently sad, empty, or low.",
      transitions: {
        1: "anxiety_01",  // no low mood → skip module
        2: "anxiety_01",
        3: "mood_02",
        4: "mood_02",
        5: "mood_02",
      },
    ),

    "mood_02": Question(
      id: "mood_02",
      module: "mood",
      text: "My low mood is present for most of the day, nearly every day.",
      transitions: {
        1: "mood_05",   // occasional → skip to anhedonia
        2: "mood_05",
        3: "mood_03",
        4: "mood_03",
        5: "mood_03",
      },
    ),

    "mood_03": Question(
      id: "mood_03",
      module: "mood",
      text: "I feel tearful or emotionally numb without a clear external reason.",
      transitions: {
        1: "mood_05",
        2: "mood_05",
        3: "mood_04",
        4: "mood_04",
        5: "mood_04",
      },
    ),

    "mood_04": Question(
      id: "mood_04",
      module: "mood",
      text: "My low mood has persisted for several weeks rather than just a few days.",
      transitions: {
        1: "mood_05",
        2: "mood_05",
        3: "mood_05",
        4: "mood_05",
        5: "mood_05",
      },
    ),

    // ── Feature 6: Anhedonia (Loss of Interest / Pleasure) ───────

    "mood_05": Question(
      id: "mood_05",
      module: "mood",
      text: "I have lost interest in hobbies or activities I used to enjoy.",
      transitions: {
        1: "mood_09",   // still has interest → skip to hopelessness
        2: "mood_09",
        3: "mood_06",
        4: "mood_06",
        5: "mood_06",
      },
    ),

    "mood_06": Question(
      id: "mood_06",
      module: "mood",
      text: "I no longer look forward to things the way I once did.",
      transitions: {
        1: "mood_09",
        2: "mood_09",
        3: "mood_07",
        4: "mood_07",
        5: "mood_07",
      },
    ),

    "mood_07": Question(
      id: "mood_07",
      module: "mood",
      text: "Even when I do things I used to enjoy, I feel little or no pleasure.",
      transitions: {
        1: "mood_09",
        2: "mood_09",
        3: "mood_08",
        4: "mood_08",
        5: "mood_08",
      },
    ),

    "mood_08": Question(
      id: "mood_08",
      module: "mood",
      text: "I have withdrawn from social activities because they feel meaningless or joyless.",
      transitions: {
        1: "mood_09",
        2: "mood_09",
        3: "mood_09",
        4: "mood_09",
        5: "mood_09",
      },
    ),

    // ── Feature 7: Hopelessness / Pessimism ──────────────────────

    "mood_09": Question(
      id: "mood_09",
      module: "mood",
      text: "I feel hopeless about the future.",
      transitions: {
        1: "mood_13",   // hopeful → skip to self-worth
        2: "mood_13",
        3: "mood_10",
        4: "mood_10",
        5: "mood_10",
      },
    ),

    "mood_10": Question(
      id: "mood_10",
      module: "mood",
      text: "I find it very hard to imagine things getting better.",
      transitions: {
        1: "mood_13",
        2: "mood_13",
        3: "mood_11",
        4: "mood_11",
        5: "mood_11",
      },
    ),

    "mood_11": Question(
      id: "mood_11",
      module: "mood",
      text: "I feel like a burden to the people around me.",
      transitions: {
        1: "mood_13",
        2: "mood_13",
        3: "mood_12",
        4: "mood_12",
        5: "mood_12",
      },
    ),

    "mood_12": Question(
      id: "mood_12",
      module: "mood",
      text: "I have given up on goals or plans that once mattered to me.",
      transitions: {
        1: "mood_13",
        2: "mood_13",
        3: "mood_13",
        4: "mood_13",
        5: "mood_13",
      },
    ),

    // ── Feature 8: Self-Worth / Guilt ────────────────────────────

    "mood_13": Question(
      id: "mood_13",
      module: "mood",
      text: "I feel worthless or like I am a failure.",
      transitions: {
        1: "mood_18",   // healthy self-worth → skip to ideation check
        2: "mood_18",
        3: "mood_14",
        4: "mood_14",
        5: "mood_14",
      },
    ),

    "mood_14": Question(
      id: "mood_14",
      module: "mood",
      text: "I blame myself excessively for things that go wrong.",
      transitions: {
        1: "mood_18",
        2: "mood_18",
        3: "mood_15",
        4: "mood_15",
        5: "mood_15",
      },
    ),

    "mood_15": Question(
      id: "mood_15",
      module: "mood",
      text: "I feel deep shame about who I am or things I have done.",
      transitions: {
        1: "mood_18",
        2: "mood_18",
        3: "mood_16",
        4: "mood_16",
        5: "mood_16",
      },
    ),

    "mood_16": Question(
      id: "mood_16",
      module: "mood",
      text: "My sense of self-worth depends heavily on the approval of others.",
      transitions: {
        1: "mood_18",
        2: "mood_18",
        3: "mood_17",
        4: "mood_17",
        5: "mood_17",
      },
    ),

    "mood_17": Question(
      id: "mood_17",
      module: "mood",
      text: "I have been excessively self-critical in ways that feel difficult to control.",
      transitions: {
        1: "mood_18",
        2: "mood_18",
        3: "mood_18",
        4: "mood_18",
        5: "mood_18",
      },
    ),

    // ── Feature 9: Suicidal / Self-Harm Ideation ─────────────────

    "mood_18": Question(
      id: "mood_18",
      module: "mood",
      text: "I have had thoughts that life is not worth living.",
      transitions: {
        1: "anxiety_01",  // no ideation → exit mood module
        2: "anxiety_01",
        3: "mood_19",
        4: "mood_19",
        5: "mood_19",
      },
    ),

    "mood_19": Question(
      id: "mood_19",
      module: "mood",
      text: "I have had thoughts about harming myself or ending my life.",
      transitions: {
        1: "anxiety_01",
        2: "anxiety_01",
        3: "mood_20",
        4: "mood_20",
        5: "mood_20",
      },
    ),

    "mood_20": Question(
      id: "mood_20",
      module: "mood",
      text: "These thoughts have been frequent or very difficult to dismiss.",
      transitions: {
        1: "anxiety_01",
        2: "anxiety_01",
        3: "mood_21",
        4: "mood_21",
        5: "mood_21",
      },
    ),

    "mood_21": Question(
      id: "mood_21",
      module: "mood",
      text: "I have made or thought about making a specific plan related to self-harm.",
      transitions: {
        1: "anxiety_01",
        2: "anxiety_01",
        3: "mood_22",
        4: "mood_22",
        5: "mood_22",
      },
    ),

    "mood_22": Question(
      id: "mood_22",
      module: "mood",
      text: "I have spoken to a friend, family member, or professional about these thoughts.",
      transitions: {
        1: "anxiety_01",
        2: "anxiety_01",
        3: "anxiety_01",
        4: "anxiety_01",
        5: "anxiety_01",
      },
    ),

    // ============================================================
    //  MODULE 3 · ANXIETY  (anxiety_01–20, 4 features)
    // ============================================================

    // ── Feature 10: General Anxiety / Tension ────────────────────

    /// ENTRY — general anxiety gate
    "anxiety_01": Question(
      id: "anxiety_01",
      module: "anxiety",
      text: "I feel tense, on edge, or keyed up.",
      transitions: {
        1: "social_01",  // no anxiety → skip module
        2: "social_01",
        3: "anxiety_02",
        4: "anxiety_02",
        5: "anxiety_02",
      },
    ),

    "anxiety_02": Question(
      id: "anxiety_02",
      module: "anxiety",
      text: "I find it hard to relax even when there is no immediate pressure.",
      transitions: {
        1: "anxiety_06",  // relaxes easily → skip to worry feature
        2: "anxiety_06",
        3: "anxiety_03",
        4: "anxiety_03",
        5: "anxiety_03",
      },
    ),

    "anxiety_03": Question(
      id: "anxiety_03",
      module: "anxiety",
      text: "I feel restless and have difficulty sitting still.",
      transitions: {
        1: "anxiety_06",
        2: "anxiety_06",
        3: "anxiety_04",
        4: "anxiety_04",
        5: "anxiety_04",
      },
    ),

    "anxiety_04": Question(
      id: "anxiety_04",
      module: "anxiety",
      text: "I am easily startled or feel unusually jumpy.",
      transitions: {
        1: "anxiety_06",
        2: "anxiety_06",
        3: "anxiety_05",
        4: "anxiety_05",
        5: "anxiety_05",
      },
    ),

    "anxiety_05": Question(
      id: "anxiety_05",
      module: "anxiety",
      text: "My anxiety feels constant and very difficult to switch off.",
      transitions: {
        1: "anxiety_06",
        2: "anxiety_06",
        3: "anxiety_06",
        4: "anxiety_06",
        5: "anxiety_06",
      },
    ),

    // ── Feature 11: Excessive / Uncontrollable Worry ─────────────

    "anxiety_06": Question(
      id: "anxiety_06",
      module: "anxiety",
      text: "I worry excessively about multiple areas of my life at once.",
      transitions: {
        1: "anxiety_11",  // not a worrier → skip to physical symptoms
        2: "anxiety_11",
        3: "anxiety_07",
        4: "anxiety_07",
        5: "anxiety_07",
      },
    ),

    "anxiety_07": Question(
      id: "anxiety_07",
      module: "anxiety",
      text: "My worries feel out of proportion to the actual situation.",
      transitions: {
        1: "anxiety_11",
        2: "anxiety_11",
        3: "anxiety_08",
        4: "anxiety_08",
        5: "anxiety_08",
      },
    ),

    "anxiety_08": Question(
      id: "anxiety_08",
      module: "anxiety",
      text: "I find it very difficult to stop or control my worrying.",
      transitions: {
        1: "anxiety_11",
        2: "anxiety_11",
        3: "anxiety_09",
        4: "anxiety_09",
        5: "anxiety_09",
      },
    ),

    "anxiety_09": Question(
      id: "anxiety_09",
      module: "anxiety",
      text: "I automatically jump to imagining worst-case scenarios.",
      transitions: {
        1: "anxiety_11",
        2: "anxiety_11",
        3: "anxiety_10",
        4: "anxiety_10",
        5: "anxiety_10",
      },
    ),

    "anxiety_10": Question(
      id: "anxiety_10",
      module: "anxiety",
      text: "Worrying takes up a significant amount of my time and mental energy each day.",
      transitions: {
        1: "anxiety_11",
        2: "anxiety_11",
        3: "anxiety_11",
        4: "anxiety_11",
        5: "anxiety_11",
      },
    ),

    // ── Feature 12: Physical Anxiety Symptoms ────────────────────

    "anxiety_11": Question(
      id: "anxiety_11",
      module: "anxiety",
      text: "I experience physical symptoms of anxiety such as a racing heart or shortness of breath.",
      transitions: {
        1: "anxiety_16",  // no physical symptoms → skip to avoidance
        2: "anxiety_16",
        3: "anxiety_12",
        4: "anxiety_12",
        5: "anxiety_12",
      },
    ),

    "anxiety_12": Question(
      id: "anxiety_12",
      module: "anxiety",
      text: "I have had sudden surges of intense, overwhelming fear.",
      transitions: {
        1: "anxiety_16",
        2: "anxiety_16",
        3: "anxiety_13",
        4: "anxiety_13",
        5: "anxiety_13",
      },
    ),

    "anxiety_13": Question(
      id: "anxiety_13",
      module: "anxiety",
      text: "During anxious moments I feel dizzy, nauseous, or physically unwell.",
      transitions: {
        1: "anxiety_16",
        2: "anxiety_16",
        3: "anxiety_14",
        4: "anxiety_14",
        5: "anxiety_14",
      },
    ),

    "anxiety_14": Question(
      id: "anxiety_14",
      module: "anxiety",
      text: "I have experienced panic attacks — sudden overwhelming fear with strong physical symptoms.",
      transitions: {
        1: "anxiety_16",
        2: "anxiety_16",
        3: "anxiety_15",
        4: "anxiety_15",
        5: "anxiety_15",
      },
    ),

    "anxiety_15": Question(
      id: "anxiety_15",
      module: "anxiety",
      text: "My physical anxiety symptoms interfere with my ability to function normally.",
      transitions: {
        1: "anxiety_16",
        2: "anxiety_16",
        3: "anxiety_16",
        4: "anxiety_16",
        5: "anxiety_16",
      },
    ),

    // ── Feature 13: Avoidance Behavior ───────────────────────────

    "anxiety_16": Question(
      id: "anxiety_16",
      module: "anxiety",
      text: "I avoid situations, places, or activities because they make me anxious.",
      transitions: {
        1: "social_01",  // no avoidance → exit anxiety module
        2: "social_01",
        3: "anxiety_17",
        4: "anxiety_17",
        5: "anxiety_17",
      },
    ),

    "anxiety_17": Question(
      id: "anxiety_17",
      module: "anxiety",
      text: "My avoidance has caused me to miss out on important events or opportunities.",
      transitions: {
        1: "social_01",
        2: "social_01",
        3: "anxiety_18",
        4: "anxiety_18",
        5: "anxiety_18",
      },
    ),

    "anxiety_18": Question(
      id: "anxiety_18",
      module: "anxiety",
      text: "I need reassurance from others to feel comfortable making everyday decisions.",
      transitions: {
        1: "social_01",
        2: "social_01",
        3: "anxiety_19",
        4: "anxiety_19",
        5: "anxiety_19",
      },
    ),

    "anxiety_19": Question(
      id: "anxiety_19",
      module: "anxiety",
      text: "I have developed repetitive rituals or safety behaviors to manage my anxiety.",
      transitions: {
        1: "social_01",
        2: "social_01",
        3: "anxiety_20",
        4: "anxiety_20",
        5: "anxiety_20",
      },
    ),

    "anxiety_20": Question(
      id: "anxiety_20",
      module: "anxiety",
      text: "My anxiety significantly restricts my life or prevents me from doing things I want to do.",
      transitions: {
        1: "social_01",
        2: "social_01",
        3: "social_01",
        4: "social_01",
        5: "social_01",
      },
    ),

    // ============================================================
    //  MODULE 4 · SOCIAL  (social_01–16, 3 features)
    //
    //  NOTE: social_01 is REVERSE SCORED.
    //    4–5 = feels connected (healthy) → skip module
    //    1–3 = low connection (problem)  → probe deeper
    // ============================================================

    // ── Feature 14: Social Connectedness ─────────────────────────

    /// ENTRY — reverse scored: connected = skip
    "social_01": Question(
      id: "social_01",
      module: "social",
      text: "I feel genuinely connected to and supported by the people in my life.",
      transitions: {
        1: "social_02",  // low connection → full branch
        2: "social_02",
        3: "social_02",  // moderate → probe
        4: "energy_01",  // feels connected → skip social module
        5: "energy_01",
      },
    ),

    "social_02": Question(
      id: "social_02",
      module: "social",
      text: "I feel lonely even when I am physically around other people.",
      transitions: {
        1: "social_06",  // not lonely → skip to withdrawal
        2: "social_06",
        3: "social_03",
        4: "social_03",
        5: "social_03",
      },
    ),

    "social_03": Question(
      id: "social_03",
      module: "social",
      text: "I feel like no one truly understands me.",
      transitions: {
        1: "social_06",
        2: "social_06",
        3: "social_04",
        4: "social_04",
        5: "social_04",
      },
    ),

    "social_04": Question(
      id: "social_04",
      module: "social",
      text: "I lack close, meaningful relationships in my life.",
      transitions: {
        1: "social_06",
        2: "social_06",
        3: "social_05",
        4: "social_05",
        5: "social_05",
      },
    ),

    "social_05": Question(
      id: "social_05",
      module: "social",
      text: "My sense of loneliness has been persistent rather than occasional.",
      transitions: {
        1: "social_06",
        2: "social_06",
        3: "social_06",
        4: "social_06",
        5: "social_06",
      },
    ),

    // ── Feature 15: Social Withdrawal ────────────────────────────

    "social_06": Question(
      id: "social_06",
      module: "social",
      text: "I avoid or withdraw from social gatherings and interactions.",
      transitions: {
        1: "social_11",  // not withdrawing → skip to conflict
        2: "social_11",
        3: "social_07",
        4: "social_07",
        5: "social_07",
      },
    ),

    "social_07": Question(
      id: "social_07",
      module: "social",
      text: "I have been canceling plans and preferring to stay at home alone.",
      transitions: {
        1: "social_11",
        2: "social_11",
        3: "social_08",
        4: "social_08",
        5: "social_08",
      },
    ),

    "social_08": Question(
      id: "social_08",
      module: "social",
      text: "I find it difficult to initiate contact with friends or family.",
      transitions: {
        1: "social_11",
        2: "social_11",
        3: "social_09",
        4: "social_09",
        5: "social_09",
      },
    ),

    "social_09": Question(
      id: "social_09",
      module: "social",
      text: "I feel a sense of relief when social plans are canceled.",
      transitions: {
        1: "social_11",
        2: "social_11",
        3: "social_10",
        4: "social_10",
        5: "social_10",
      },
    ),

    "social_10": Question(
      id: "social_10",
      module: "social",
      text: "People close to me have expressed concern about how much I have been withdrawing.",
      transitions: {
        1: "social_11",
        2: "social_11",
        3: "social_11",
        4: "social_11",
        5: "social_11",
      },
    ),

    // ── Feature 16: Interpersonal Conflict ───────────────────────

    "social_11": Question(
      id: "social_11",
      module: "social",
      text: "I frequently experience conflict or tension in my relationships.",
      transitions: {
        1: "energy_01",  // low conflict → exit social module
        2: "energy_01",
        3: "social_12",
        4: "social_12",
        5: "social_12",
      },
    ),

    "social_12": Question(
      id: "social_12",
      module: "social",
      text: "I find it hard to trust other people.",
      transitions: {
        1: "energy_01",
        2: "energy_01",
        3: "social_13",
        4: "social_13",
        5: "social_13",
      },
    ),

    "social_13": Question(
      id: "social_13",
      module: "social",
      text: "I feel easily hurt, dismissed, or rejected by others.",
      transitions: {
        1: "energy_01",
        2: "energy_01",
        3: "social_14",
        4: "social_14",
        5: "social_14",
      },
    ),

    "social_14": Question(
      id: "social_14",
      module: "social",
      text: "My relationships tend to be unstable, intense, or unpredictable.",
      transitions: {
        1: "energy_01",
        2: "energy_01",
        3: "social_15",
        4: "social_15",
        5: "social_15",
      },
    ),

    "social_15": Question(
      id: "social_15",
      module: "social",
      text: "I have difficulty expressing my needs or setting healthy boundaries with others.",
      transitions: {
        1: "energy_01",
        2: "energy_01",
        3: "social_16",
        4: "social_16",
        5: "social_16",
      },
    ),

    "social_16": Question(
      id: "social_16",
      module: "social",
      text: "Relationship difficulties significantly affect my overall wellbeing.",
      transitions: {
        1: "energy_01",
        2: "energy_01",
        3: "energy_01",
        4: "energy_01",
        5: "energy_01",
      },
    ),

    // ============================================================
    //  MODULE 5 · ENERGY  (energy_01–14, 2 features)
    // ============================================================

    // ── Feature 17: Fatigue / Energy Levels ──────────────────────

    /// ENTRY — fatigue gate
    "energy_01": Question(
      id: "energy_01",
      module: "energy",
      text: "I feel physically or mentally exhausted for most of the day.",
      transitions: {
        1: "cognitive_01",  // good energy → skip module
        2: "cognitive_01",
        3: "energy_02",
        4: "energy_02",
        5: "energy_02",
      },
    ),

    "energy_02": Question(
      id: "energy_02",
      module: "energy",
      text: "My energy levels are significantly lower than they used to be.",
      transitions: {
        1: "energy_08",   // energy unchanged → skip to appetite
        2: "energy_08",
        3: "energy_03",
        4: "energy_03",
        5: "energy_03",
      },
    ),

    "energy_03": Question(
      id: "energy_03",
      module: "energy",
      text: "I feel fatigued even after minimal physical or mental effort.",
      transitions: {
        1: "energy_08",
        2: "energy_08",
        3: "energy_04",
        4: "energy_04",
        5: "energy_04",
      },
    ),

    "energy_04": Question(
      id: "energy_04",
      module: "energy",
      text: "My fatigue makes it difficult to complete everyday tasks.",
      transitions: {
        1: "energy_08",
        2: "energy_08",
        3: "energy_05",
        4: "energy_05",
        5: "energy_05",
      },
    ),

    "energy_05": Question(
      id: "energy_05",
      module: "energy",
      text: "I feel physically heavy or as though I am moving through mud.",
      transitions: {
        1: "energy_08",
        2: "energy_08",
        3: "energy_06",
        4: "energy_06",
        5: "energy_06",
      },
    ),

    "energy_06": Question(
      id: "energy_06",
      module: "energy",
      text: "I have stopped or significantly reduced physical activity because I lack the energy.",
      transitions: {
        1: "energy_08",
        2: "energy_08",
        3: "energy_07",
        4: "energy_07",
        5: "energy_07",
      },
    ),

    "energy_07": Question(
      id: "energy_07",
      module: "energy",
      text: "My fatigue has no clear physical explanation such as illness or medication.",
      transitions: {
        1: "energy_08",
        2: "energy_08",
        3: "energy_08",
        4: "energy_08",
        5: "energy_08",
      },
    ),

    // ── Feature 18: Appetite / Physical Wellbeing ────────────────

    "energy_08": Question(
      id: "energy_08",
      module: "energy",
      text: "My appetite has noticeably increased or decreased recently.",
      transitions: {
        1: "cognitive_01",  // stable appetite → skip to cognitive
        2: "cognitive_01",
        3: "energy_09",
        4: "energy_09",
        5: "energy_09",
      },
    ),

    "energy_09": Question(
      id: "energy_09",
      module: "energy",
      text: "I eat significantly more or less than I used to.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "energy_10",
        4: "energy_10",
        5: "energy_10",
      },
    ),

    "energy_10": Question(
      id: "energy_10",
      module: "energy",
      text: "My relationship with food feels out of control or is causing me distress.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "energy_11",
        4: "energy_11",
        5: "energy_11",
      },
    ),

    "energy_11": Question(
      id: "energy_11",
      module: "energy",
      text: "I have noticed significant or unwanted changes in my body weight recently.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "energy_12",
        4: "energy_12",
        5: "energy_12",
      },
    ),

    "energy_12": Question(
      id: "energy_12",
      module: "energy",
      text: "I tend to skip meals or overeat in response to stress or emotional states.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "energy_13",
        4: "energy_13",
        5: "energy_13",
      },
    ),

    "energy_13": Question(
      id: "energy_13",
      module: "energy",
      text: "I experience physical symptoms such as headaches, stomach problems, or body pain when under stress.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "energy_14",
        4: "energy_14",
        5: "energy_14",
      },
    ),

    "energy_14": Question(
      id: "energy_14",
      module: "energy",
      text: "I neglect my physical health — diet, exercise, or medical care — because of how I feel emotionally.",
      transitions: {
        1: "cognitive_01",
        2: "cognitive_01",
        3: "cognitive_01",
        4: "cognitive_01",
        5: "cognitive_01",
      },
    ),

    // ============================================================
    //  MODULE 6 · COGNITIVE  (cognitive_01–12, 2 features)
    // ============================================================

    // ── Feature 19: Concentration / Focus ────────────────────────

    /// ENTRY — cognitive gate
    "cognitive_01": Question(
      id: "cognitive_01",
      module: "cognitive",
      text: "I find it very difficult to concentrate on tasks.",
      transitions: {
        1: "end",           // good concentration → finish
        2: "end",
        3: "cognitive_02",
        4: "cognitive_02",
        5: "cognitive_02",
      },
    ),

    "cognitive_02": Question(
      id: "cognitive_02",
      module: "cognitive",
      text: "My mind wanders frequently, even during important conversations or activities.",
      transitions: {
        1: "cognitive_07",  // stays focused → skip to memory/decisions
        2: "cognitive_07",
        3: "cognitive_03",
        4: "cognitive_03",
        5: "cognitive_03",
      },
    ),

    "cognitive_03": Question(
      id: "cognitive_03",
      module: "cognitive",
      text: "I frequently have to re-read things or redo tasks because I could not focus the first time.",
      transitions: {
        1: "cognitive_07",
        2: "cognitive_07",
        3: "cognitive_04",
        4: "cognitive_04",
        5: "cognitive_04",
      },
    ),

    "cognitive_04": Question(
      id: "cognitive_04",
      module: "cognitive",
      text: "I struggle to stay mentally present during meetings, classes, or conversations.",
      transitions: {
        1: "cognitive_07",
        2: "cognitive_07",
        3: "cognitive_05",
        4: "cognitive_05",
        5: "cognitive_05",
      },
    ),

    "cognitive_05": Question(
      id: "cognitive_05",
      module: "cognitive",
      text: "My ability to concentrate feels noticeably worse than it used to be.",
      transitions: {
        1: "cognitive_07",
        2: "cognitive_07",
        3: "cognitive_06",
        4: "cognitive_06",
        5: "cognitive_06",
      },
    ),

    "cognitive_06": Question(
      id: "cognitive_06",
      module: "cognitive",
      text: "Poor concentration has negatively affected my work, studies, or important responsibilities.",
      transitions: {
        1: "cognitive_07",
        2: "cognitive_07",
        3: "cognitive_07",
        4: "cognitive_07",
        5: "cognitive_07",
      },
    ),

    // ── Feature 20: Decision-Making / Memory ─────────────────────

    "cognitive_07": Question(
      id: "cognitive_07",
      module: "cognitive",
      text: "I find it hard to make decisions, even relatively minor ones.",
      transitions: {
        1: "end",           // decisive → finish
        2: "end",
        3: "cognitive_08",
        4: "cognitive_08",
        5: "cognitive_08",
      },
    ),

    "cognitive_08": Question(
      id: "cognitive_08",
      module: "cognitive",
      text: "I frequently second-guess decisions I have already made.",
      transitions: {
        1: "end",
        2: "end",
        3: "cognitive_09",
        4: "cognitive_09",
        5: "cognitive_09",
      },
    ),

    "cognitive_09": Question(
      id: "cognitive_09",
      module: "cognitive",
      text: "My memory feels noticeably worse than it used to be.",
      transitions: {
        1: "end",
        2: "end",
        3: "cognitive_10",
        4: "cognitive_10",
        5: "cognitive_10",
      },
    ),

    "cognitive_10": Question(
      id: "cognitive_10",
      module: "cognitive",
      text: "I forget things I would previously have remembered easily.",
      transitions: {
        1: "end",
        2: "end",
        3: "cognitive_11",
        4: "cognitive_11",
        5: "cognitive_11",
      },
    ),

    "cognitive_11": Question(
      id: "cognitive_11",
      module: "cognitive",
      text: "My thinking feels slow, foggy, or unclear — sometimes called brain fog.",
      transitions: {
        1: "end",
        2: "end",
        3: "cognitive_12",
        4: "cognitive_12",
        5: "cognitive_12",
      },
    ),

    "cognitive_12": Question(
      id: "cognitive_12",
      module: "cognitive",
      text: "Difficulties with thinking, memory, or decisions have significantly impacted my daily life.",
      transitions: {
        1: "end",
        2: "end",
        3: "end",
        4: "end",
        5: "end",
      },
    ),
  };
}