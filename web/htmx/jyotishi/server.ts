import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";

const app = new Hono();

// ── Vedic Ephemeris Engine (mean orbital elements, J2000 epoch) ───────────────
// Sources: Meeus "Astronomical Algorithms" & NASA JPL mean elements

const J2000_JD = 2451545.0;
const AYANAMSA_J2000 = 23.8566; // Lahiri at J2000.0, degrees
const AYANAMSA_RATE  = 0.000138889; // ~50" per year → deg/day ÷ 365.25 * rate

function julianDate(d: Date): number {
  return d.getTime() / 86400000 + 2440587.5;
}

function mod360(x: number): number {
  return ((x % 360) + 360) % 360;
}

interface GrahaElement {
  name: string; hindi: string; emoji: string; color: string;
  L0: number; rate: number; // mean longitude J2000 & daily motion (°/day)
}

const GRAHAS: Record<string, GrahaElement> = {
  surya:   { name: "Surya",   hindi: "सूर्य", emoji: "☀️", color: "#f59e0b", L0: 280.46646, rate:  0.98564736  },
  chandra: { name: "Chandra", hindi: "चन्द्र", emoji: "🌙", color: "#94a3b8", L0: 218.31665, rate: 13.17639648  },
  mangal:  { name: "Mangal",  hindi: "मंगल",  emoji: "♂",  color: "#ef4444", L0: 355.45332, rate:  0.52402068  },
  budha:   { name: "Budha",   hindi: "बुध",   emoji: "☿",  color: "#22c55e", L0: 252.25084, rate:  4.09233445  },
  guru:    { name: "Guru",    hindi: "गुरु",  emoji: "♃",  color: "#f97316", L0:  34.35644, rate:  0.08308529  },
  shukra:  { name: "Shukra",  hindi: "शुक्र", emoji: "♀",  color: "#ec4899", L0: 181.97980, rate:  1.60213034  },
  shani:   { name: "Shani",   hindi: "शनि",  emoji: "♄",  color: "#64748b", L0:  50.07747, rate:  0.03344402  },
  rahu:    { name: "Rahu",    hindi: "राहु",  emoji: "☊",  color: "#8b5cf6", L0: 125.04455, rate: -0.05295392  },
};

interface GrahaPosition extends GrahaElement {
  tropical: number; sidereal: number;
  rashiIndex: number; degInRashi: string; isRetro: boolean;
}

function computeGrahas(date: Date): GrahaPosition[] {
  const jd  = julianDate(date);
  const T   = jd - J2000_JD;                              // days since J2000
  const ayanamsa = AYANAMSA_J2000 + AYANAMSA_RATE * T;

  const positions: GrahaPosition[] = Object.entries(GRAHAS).map(([, el]) => {
    const tropical   = mod360(el.L0 + el.rate * T);
    const sidereal   = mod360(tropical - ayanamsa);
    const rashiIndex = Math.floor(sidereal / 30);
    const degInRashi = (sidereal % 30).toFixed(2);
    return { ...el, tropical, sidereal, rashiIndex, degInRashi, isRetro: el.rate < 0 };
  });

  // Ketu = Rahu + 180°
  const rahu = positions.find(p => p.name === "Rahu")!;
  const ketuSidereal   = mod360(rahu.sidereal + 180);
  const ketuRashiIndex = Math.floor(ketuSidereal / 30);
  positions.push({
    name: "Ketu", hindi: "केतु", emoji: "☋", color: "#a16207",
    L0: 0, rate: 0,
    tropical: mod360(rahu.tropical + 180),
    sidereal: ketuSidereal, rashiIndex: ketuRashiIndex,
    degInRashi: (ketuSidereal % 30).toFixed(2), isRetro: true,
  });

  return positions;
}

// Rashi list in Vedic order (Mesh = 0)
const RASHI_LIST = [
  { key: "mesh",     name: "Mesh",     hindi: "मेष",    emoji: "♈", en: "Aries"       },
  { key: "vrishabh", name: "Vrishabh", hindi: "वृषभ",   emoji: "♉", en: "Taurus"      },
  { key: "mithun",   name: "Mithun",   hindi: "मिथुन",  emoji: "♊", en: "Gemini"      },
  { key: "kark",     name: "Kark",     hindi: "कर्क",   emoji: "♋", en: "Cancer"      },
  { key: "simha",    name: "Simha",    hindi: "सिंह",   emoji: "♌", en: "Leo"         },
  { key: "kanya",    name: "Kanya",    hindi: "कन्या",  emoji: "♍", en: "Virgo"       },
  { key: "tula",     name: "Tula",     hindi: "तुला",   emoji: "♎", en: "Libra"       },
  { key: "vrishchik",name: "Vrishchik",hindi: "वृश्चिक",emoji: "♏", en: "Scorpio"     },
  { key: "dhanu",    name: "Dhanu",    hindi: "धनु",    emoji: "♐", en: "Sagittarius" },
  { key: "makar",    name: "Makar",    hindi: "मकर",    emoji: "♑", en: "Capricorn"   },
  { key: "kumbh",    name: "Kumbh",    hindi: "कुम्भ",  emoji: "♒", en: "Aquarius"    },
  { key: "meen",     name: "Meen",     hindi: "मीन",    emoji: "♓", en: "Pisces"      },
];


// ── Rashi → Western sign mapping ─────────────────────────────────────────────
const RASHI_MAP: Record<
  string,
  { sign: string; emoji: string; element: string; ruler: string; traits: string[] }
> = {
  mesh: {
    sign: "Aries",
    emoji: "♈",
    element: "Fire",
    ruler: "Mars",
    traits: ["Courageous", "Energetic", "Confident"],
  },
  vrishabh: {
    sign: "Taurus",
    emoji: "♉",
    element: "Earth",
    ruler: "Venus",
    traits: ["Reliable", "Patient", "Devoted"],
  },
  mithun: {
    sign: "Gemini",
    emoji: "♊",
    element: "Air",
    ruler: "Mercury",
    traits: ["Adaptable", "Curious", "Expressive"],
  },
  kark: {
    sign: "Cancer",
    emoji: "♋",
    element: "Water",
    ruler: "Moon",
    traits: ["Intuitive", "Emotional", "Protective"],
  },
  simha: {
    sign: "Leo",
    emoji: "♌",
    element: "Fire",
    ruler: "Sun",
    traits: ["Charismatic", "Bold", "Creative"],
  },
  kanya: {
    sign: "Virgo",
    emoji: "♍",
    element: "Earth",
    ruler: "Mercury",
    traits: ["Analytical", "Practical", "Diligent"],
  },
  tula: {
    sign: "Libra",
    emoji: "♎",
    element: "Air",
    ruler: "Venus",
    traits: ["Harmonious", "Diplomatic", "Fair"],
  },
  vrishchik: {
    sign: "Scorpio",
    emoji: "♏",
    element: "Water",
    ruler: "Mars",
    traits: ["Passionate", "Resourceful", "Brave"],
  },
  dhanu: {
    sign: "Sagittarius",
    emoji: "♐",
    element: "Fire",
    ruler: "Jupiter",
    traits: ["Optimistic", "Adventurous", "Independent"],
  },
  makar: {
    sign: "Capricorn",
    emoji: "♑",
    element: "Earth",
    ruler: "Saturn",
    traits: ["Disciplined", "Responsible", "Ambitious"],
  },
  kumbh: {
    sign: "Aquarius",
    emoji: "♒",
    element: "Air",
    ruler: "Saturn",
    traits: ["Innovative", "Humanitarian", "Original"],
  },
  meen: {
    sign: "Pisces",
    emoji: "♓",
    element: "Water",
    ruler: "Jupiter",
    traits: ["Compassionate", "Artistic", "Intuitive"],
  },
};

const ELEMENT_COLORS: Record<string, string> = {
  Fire: "#ff6b35",
  Earth: "#4caf50",
  Air: "#64b5f6",
  Water: "#ab47bc",
};

type DayParam = "today" | "tomorrow" | "yesterday";

// ── Fetch horoscope from upstream API ────────────────────────────────────────
async function fetchHoroscope(sign: string, day: DayParam) {
  const url = `https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=${sign}&day=${day.toUpperCase()}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  const json = (await res.json()) as {
    data: { horoscope: string; date: string };
  };
  return json.data;
}

// ── Helper: lucky number / color ──────────────────────────────────────────────
function getLucky(sign: string, day: string) {
  // Deterministic pseudo-random seeded on sign+day
  const seed =
    [...sign, ...day].reduce((a, c) => a + c.charCodeAt(0), 0) * 7919;
  const num = (seed % 99) + 1;
  const colors = [
    "Crimson",
    "Sapphire",
    "Emerald",
    "Amber",
    "Violet",
    "Gold",
    "Indigo",
    "Rose",
  ];
  const color = colors[seed % colors.length];
  const scores = {
    love: Math.floor(((seed * 13) % 40) + 60),
    career: Math.floor(((seed * 17) % 40) + 60),
    health: Math.floor(((seed * 11) % 40) + 60),
  };
  return { num, color, scores };
}

// ── Vedic Bhava (House) Data & Classical Gochara Analysis ───────────────────

interface BhavaInfo {
  num: number;
  sanskrit: string;
  name: string;
  domain: string;
}

const BHAVA_INFO: BhavaInfo[] = [
  { num: 1,  sanskrit: "Tanu Bhava",   name: "1st House", domain: "Self, Vitality & Appearance" },
  { num: 2,  sanskrit: "Dhana Bhava",  name: "2nd House", domain: "Wealth, Family, Speech & Assets" },
  { num: 3,  sanskrit: "Sahaja Bhava", name: "3rd House", domain: "Courage, Siblings & Self-Effort" },
  { num: 4,  sanskrit: "Sukha Bhava",  name: "4th House", domain: "Home, Inner Peace & Mother" },
  { num: 5,  sanskrit: "Putra Bhava",  name: "5th House", domain: "Intellect, Creativity & Romance" },
  { num: 6,  sanskrit: "Ari Bhava",    name: "6th House", domain: "Victory over Obstacles, Health & Work" },
  { num: 7,  sanskrit: "Yuvati Bhava", name: "7th House", domain: "Partnerships, Marriage & Public Relations" },
  { num: 8,  sanskrit: "Randhra Bhava",name: "8th House", domain: "Transformation, Intuition & Longevity" },
  { num: 9,  sanskrit: "Dharma Bhava", name: "9th House", domain: "Fortune, Higher Wisdom & Luck" },
  { num: 10, sanskrit: "Karma Bhava",  name: "10th House", domain: "Career, Authority & Actions" },
  { num: 11, sanskrit: "Labha Bhava",  name: "11th House", domain: "Gains, Desires & Social Networks" },
  { num: 12, sanskrit: "Vyaya Bhava",  name: "12th House", domain: "Expenditures, Foreign Links & Solitude" },
];

interface VedicRemedy {
  mantra: string;
  mantraEng: string;
  deity: string;
  upaya: string;
  color: string;
  metal: string;
}

const RASHI_REMEDIES: Record<string, VedicRemedy> = {
  mesh: {
    mantra: "ॐ भौं भौमाय नमः",
    mantraEng: "Om Bhaum Bhaumaya Namah",
    deity: "Lord Hanuman / Mangal Deva",
    upaya: "Offer red flowers or jaggery, channel vitality into structured workouts, and practice patience in discussions.",
    color: "Crimson Red & Coral",
    metal: "Copper"
  },
  vrishabh: {
    mantra: "ॐ शुं शुक्राय नमः",
    mantraEng: "Om Shum Shukraya Namah",
    deity: "Goddess Mahalakshmi",
    upaya: "Wear clean white or soft pastel attire, nurture harmony in family conversations, and practice financial prudence.",
    color: "Silver White & Rose",
    metal: "Silver"
  },
  mithun: {
    mantra: "ॐ बुं बुधाय नमः",
    mantraEng: "Om Bum Budhaya Namah",
    deity: "Lord Vishnu / Budha Deva",
    upaya: "Feed green grass or vegetables to birds/cows, take a walk in nature, and write down clear action goals.",
    color: "Emerald Green & Teal",
    metal: "Bronze"
  },
  kark: {
    mantra: "ॐ सों सोमाय नमः",
    mantraEng: "Om Som Somaya Namah",
    deity: "Lord Shiva / Chandra Deva",
    upaya: "Drink water from a silver cup, respect motherly figures, and dedicate 10 minutes to mindful breathing.",
    color: "Pearl White & Silver",
    metal: "Silver"
  },
  simha: {
    mantra: "ॐ घृणि सूर्याय नमः",
    mantraEng: "Om Ghrini Suryaya Namah",
    deity: "Lord Surya Narayana",
    upaya: "Offer fresh water (Arghya) to the rising Sun, show respect to mentors/father, and lead with gentle grace.",
    color: "Radiant Gold & Saffron",
    metal: "Gold / Brass"
  },
  kanya: {
    mantra: "ॐ बुं बुधाय नमः",
    mantraEng: "Om Bum Budhaya Namah",
    deity: "Lord Ganesha & Vishnu",
    upaya: "Organize your study or desk space, donate green legumes, and chant the Ganesha Atharvashirsha.",
    color: "Leaf Green & Khaki",
    metal: "Bronze"
  },
  tula: {
    mantra: "ॐ शुं शुक्राय नमः",
    mantraEng: "Om Shum Shukraya Namah",
    deity: "Goddess Lakshmi",
    upaya: "Apply natural sandalwood or rose attar, seek diplomatic win-win solutions, and treat peers with empathy.",
    color: "Pastel Blue & White",
    metal: "Silver / Platinum"
  },
  vrishchik: {
    mantra: "ॐ अं अंगारकाय नमः",
    mantraEng: "Om Am Angarakaya Namah",
    deity: "Lord Kartikeya / Hanuman",
    upaya: "Chant the Hanuman Chalisa, avoid brooding over old grudges, and channel emotional depths into creative discipline.",
    color: "Maroon & Deep Rust",
    metal: "Copper"
  },
  dhanu: {
    mantra: "ॐ बृं बृहस्पतये नमः",
    mantraEng: "Om Brim Brihaspataye Namah",
    deity: "Lord Dakshinamurthy / Brihaspati",
    upaya: "Apply a subtle saffron/turmeric tilak, seek blessings from elders or teachers, and read wisdom scriptures.",
    color: "Golden Yellow & Topaz",
    metal: "Gold"
  },
  makar: {
    mantra: "ॐ शं शनैश्चराय नमः",
    mantraEng: "Om Sham Shanaishcharaya Namah",
    deity: "Lord Shani / Lord Shiva",
    upaya: "Light a mustard oil lamp at sunset, be kind to hardworking laborers or helpers, and maintain steady diligence.",
    color: "Navy Blue & Steel Grey",
    metal: "Iron"
  },
  kumbh: {
    mantra: "ॐ शं शनैश्चराय नमः",
    mantraEng: "Om Sham Shanaishcharaya Namah",
    deity: "Lord Shiva & Rudra",
    upaya: "Contribute to a community or social welfare cause, feed stray animals, and spend time in quiet meditation.",
    color: "Electric Blue & Charcoal",
    metal: "Iron / Lead"
  },
  meen: {
    mantra: "ॐ ग्रां ग्रीं ग्रौं सः गुरवे नमः",
    mantraEng: "Om Gram Greem Groum Sah Gurave Namah",
    deity: "Lord Vishnu / Guru",
    upaya: "Practice silent meditation near water, donate yellow pulses (Chana dal) or books, and trust your intuitive feelings.",
    color: "Sea Green & Radiant Yellow",
    metal: "Gold"
  },
};

// Classical Gochara Transit Interpretation rules
function getGrahaPhala(
  grahaKey: string,
  houseNum: number,
  rashiSign: string,
  isExalted: boolean,
  isDebilitated: boolean
): { status: string; statusType: "good" | "warn" | "neutral" | "exalted"; text: string } {
  // Exalted / Debilitated overrides
  if (isExalted) {
    return {
      status: "Exalted (Uchha) 🌟",
      statusType: "exalted",
      text: `Magnified positive strength in ${houseNum}${getOrdinal(houseNum)} house. Radiates supreme cosmic dignity and auspicious blessings in this domain.`
    };
  }
  if (isDebilitated) {
    return {
      status: "Debilitated (Neecha) ⚠️",
      statusType: "warn",
      text: `Low cosmic dignity in ${houseNum}${getOrdinal(houseNum)} house. Suggests exercising patience and emotional grounding in related matters.`
    };
  }

  // Saturn special Sade Sati & Kantaka rules
  if (grahaKey === "shani") {
    if (houseNum === 12) {
      return {
        status: "Sade Sati Phase 1 (Rising) 🪐",
        statusType: "warn",
        text: "Vyaya Shani: Teaches financial discipline, spiritual introspection, and shedding superficial mental baggage."
      };
    }
    if (houseNum === 1) {
      return {
        status: "Sade Sati Phase 2 (Peak) 🪐",
        statusType: "warn",
        text: "Janma Shani: Heavy karmic responsibilities that build enduring endurance, mature character, and self-mastery."
      };
    }
    if (houseNum === 2) {
      return {
        status: "Sade Sati Phase 3 (Setting) 🪐",
        statusType: "neutral",
        text: "Dhana Shani: Rebuilding family wealth, establishing grounded values, and speaking with measured truth."
      };
    }
    if (houseNum === 4) {
      return {
        status: "Kantaka Shani ⚖️",
        statusType: "warn",
        text: "Ardh-Ashtama transit calls for patience in domestic affairs and taking calm care of mental and physical rest."
      };
    }
    if (houseNum === 8) {
      return {
        status: "Ashtama Shani ⚠️",
        statusType: "warn",
        text: "Calls for caution during travel, disciplined routines, and spiritual surrender to transformational changes."
      };
    }
    if ([3, 6, 11].includes(houseNum)) {
      return {
        status: "Upachaya Victory ✦",
        statusType: "good",
        text: `Highly auspicious transit in ${houseNum}${getOrdinal(houseNum)} house! Conquers obstacles and yields solid, permanent rewards through steady effort.`
      };
    }
  }

  // Moon special Ashtama Chandra rule
  if (grahaKey === "chandra") {
    if (houseNum === 8) {
      return {
        status: "Ashtama Chandra 🌙",
        statusType: "warn",
        text: "Moon in 8th house brings deep emotional sensitivity and intuition. Excellent for spiritual sadhana; postpone major speculative gambles."
      };
    }
    if ([1, 3, 6, 7, 10, 11].includes(houseNum)) {
      return {
        status: "Shubha Gochara ✨",
        statusType: "good",
        text: `Favorable transit in ${houseNum}${getOrdinal(houseNum)} house, fostering mental clarity, social rapport, and cheerful enthusiasm.`
      };
    }
  }

  // Sun (Surya)
  if (grahaKey === "surya") {
    if ([3, 6, 10, 11].includes(houseNum)) {
      return {
        status: "Upachaya Radiant ☀️",
        statusType: "good",
        text: `Auspicious transit in ${houseNum}${getOrdinal(houseNum)} house: Defeats competition, vitalizes physical energy, and boosts leadership authority.`
      };
    }
    return {
      status: "Transformative ⚖️",
      statusType: "neutral",
      text: `Sun highlights the ${houseNum}${getOrdinal(houseNum)} house domain; practice hydration, humility, and calm communication.`
    };
  }

  // Mars (Mangal)
  if (grahaKey === "mangal") {
    if ([3, 6, 11].includes(houseNum)) {
      return {
        status: "Shatru-Vijaya ♂",
        statusType: "good",
        text: `Victorious transit in ${houseNum}${getOrdinal(houseNum)} house: High stamina, bold decision-making, and rapid breakthroughs.`
      };
    }
    return {
      status: "High Energy ⚡",
      statusType: "warn",
      text: `Dynamic force in ${houseNum}${getOrdinal(houseNum)} house; channel assertiveness into productive tasks rather than arguments.`
    };
  }

  // Jupiter (Guru)
  if (grahaKey === "guru") {
    if ([2, 5, 7, 9, 11].includes(houseNum) || [1, 4, 10].includes(houseNum)) {
      return {
        status: "Deva-Kripa 🌟",
        statusType: "good",
        text: `Benevolent grace in ${houseNum}${getOrdinal(houseNum)} house: Expands wisdom, brings ethical fortune, and shields against distress.`
      };
    }
    return {
      status: "Guiding Light ♃",
      statusType: "good",
      text: `Jupiter fosters learning and gradual wisdom in the ${houseNum}${getOrdinal(houseNum)} house sphere.`
    };
  }

  // Venus (Shukra)
  if (grahaKey === "shukra") {
    if (![6, 7, 10].includes(houseNum)) {
      return {
        status: "Auspicious Charm ♀",
        statusType: "good",
        text: `Harmony and aesthetic joy in ${houseNum}${getOrdinal(houseNum)} house: Promotes cordial relationships and creative satisfaction.`
      };
    }
    return {
      status: "Diplomatic Focus ⚖️",
      statusType: "neutral",
      text: `Venus asks for tact and balance in the ${houseNum}${getOrdinal(houseNum)} house matters.`
    };
  }

  // Mercury (Budha)
  if (grahaKey === "budha") {
    if ([2, 4, 6, 8, 10, 11].includes(houseNum)) {
      return {
        status: "Intellectual Flow ☿",
        statusType: "good",
        text: `Sharp wit and communicative prowess in ${houseNum}${getOrdinal(houseNum)} house: Fosters successful negotiations and problem-solving.`
      };
    }
    return {
      status: "Mental Focus ⚖️",
      statusType: "neutral",
      text: `Active curiosity in ${houseNum}${getOrdinal(houseNum)} house; double-check written details and contracts.`
    };
  }

  // Rahu / Ketu
  if (grahaKey === "rahu") {
    if ([3, 6, 10, 11].includes(houseNum)) {
      return {
        status: "Material Surge ☊",
        statusType: "good",
        text: `Unconventional gains and strong drive in ${houseNum}${getOrdinal(houseNum)} house; favors forward-thinking ventures.`
      };
    }
    return {
      status: "Karmic Shift 🌪️",
      statusType: "warn",
      text: `Desire and ambition active in ${houseNum}${getOrdinal(houseNum)} house; keep actions anchored in ethical grounding.`
    };
  }

  if (grahaKey === "ketu") {
    if ([3, 6, 9, 11, 12].includes(houseNum)) {
      return {
        status: "Spiritual Insight ☋",
        statusType: "good",
        text: `Quiet wisdom and intuitive detachment in ${houseNum}${getOrdinal(houseNum)} house; great for meditation and self-discovery.`
      };
    }
    return {
      status: "Detachment ⚖️",
      statusType: "neutral",
      text: `Encourages releasing expectations in ${houseNum}${getOrdinal(houseNum)} house affairs.`
    };
  }

  return { status: "Active Transit", statusType: "neutral", text: `Transiting the ${houseNum}${getOrdinal(houseNum)} house.` };
}

function getOrdinal(n: number): string {
  const s = ["th", "st", "nd", "rd"];
  const v = n % 100;
  return s[(v - 20) % 10] || s[v] || s[0];
}

interface GocharaAnalysis {
  userRashi: string;
  rashiIndex: number;
  highlightBadges: { icon: string; text: string; type: "good" | "warn" | "neutral" | "exalted" }[];
  synthesisHtml: string;
  transits: {
    grahaKey: string;
    emoji: string;
    name: string;
    color: string;
    transitRashi: string;
    degInRashi: string;
    isRetro: boolean;
    houseNum: number;
    bhavaSanskrit: string;
    bhavaDomain: string;
    status: string;
    statusType: "good" | "warn" | "neutral" | "exalted";
    phala: string;
  }[];
  remedy: VedicRemedy;
}

function analyzeGochara(rashiKey: string, grahas: GrahaPosition[]): GocharaAnalysis {
  const userRashiIndex = RASHI_LIST.findIndex((r) => r.key === rashiKey);
  const rashiMeta = RASHI_LIST[userRashiIndex] || RASHI_LIST[0];
  const remedy = RASHI_REMEDIES[rashiKey] || RASHI_REMEDIES.mesh;

  const highlights: { icon: string; text: string; type: "good" | "warn" | "neutral" | "exalted" }[] = [];

  // Exaltation indices: Surya:0, Chandra:1, Mangal:9, Budha:5, Guru:3, Shukra:11, Shani:6
  const exaltationMap: Record<string, number> = {
    Surya: 0, Chandra: 1, Mangal: 9, Budha: 5, Guru: 3, Shukra: 11, Shani: 6
  };
  const debilitationMap: Record<string, number> = {
    Surya: 6, Chandra: 7, Mangal: 3, Budha: 11, Guru: 9, Shukra: 5, Shani: 0
  };

  const transits = grahas.map((g) => {
    const houseNum = ((g.rashiIndex - userRashiIndex + 12) % 12) + 1;
    const bhava = BHAVA_INFO[houseNum - 1];
    const transitRashi = RASHI_LIST[g.rashiIndex].name;
    const grahaKey = g.name.toLowerCase();

    const isExalted = exaltationMap[g.name] === g.rashiIndex;
    const isDebilitated = debilitationMap[g.name] === g.rashiIndex;

    const phalaInfo = getGrahaPhala(grahaKey, houseNum, transitRashi, isExalted, isDebilitated);

    // Build highlights
    if (isExalted) {
      highlights.push({ icon: "🌟", text: `${g.name} Exalted in ${houseNum}${getOrdinal(houseNum)} House (${transitRashi})`, type: "exalted" });
    }
    if (grahaKey === "shani" && [12, 1, 2].includes(houseNum)) {
      const phase = houseNum === 12 ? "Rising" : houseNum === 1 ? "Peak" : "Setting";
      highlights.push({ icon: "🪐", text: `Shani Sade Sati (${phase} Phase)`, type: "warn" });
    } else if (grahaKey === "shani" && houseNum === 8) {
      highlights.push({ icon: "⚠️", text: "Ashtama Shani Active", type: "warn" });
    }
    if (grahaKey === "chandra" && houseNum === 8) {
      highlights.push({ icon: "🌙", text: "Ashtama Chandra (Mindful Day)", type: "warn" });
    }
    if (grahaKey === "surya" && [3, 6, 10, 11].includes(houseNum)) {
      highlights.push({ icon: "☀️", text: `Surya in ${houseNum}${getOrdinal(houseNum)} House (Victory Upachaya)`, type: "good" });
    }
    if (grahaKey === "guru" && [1, 4, 5, 7, 9, 11].includes(houseNum) && !isExalted) {
      highlights.push({ icon: "♃", text: `Guru Blesses ${houseNum}${getOrdinal(houseNum)} House (${bhava.sanskrit})`, type: "good" });
    }

    return {
      grahaKey,
      emoji: g.emoji,
      name: g.name,
      color: g.color,
      transitRashi,
      degInRashi: g.degInRashi,
      isRetro: g.isRetro,
      houseNum,
      bhavaSanskrit: bhava.sanskrit,
      bhavaDomain: bhava.domain,
      status: phalaInfo.status,
      statusType: phalaInfo.statusType,
      phala: phalaInfo.text,
    };
  });

  // Default highlight if few
  if (highlights.length === 0) {
    highlights.push({ icon: "✨", text: "Balanced Planetary Gochara", type: "neutral" });
  }

  // Find key planets for narrative
  const suryaTransit = transits.find((t) => t.grahaKey === "surya")!;
  const chandraTransit = transits.find((t) => t.grahaKey === "chandra")!;
  const guruTransit = transits.find((t) => t.grahaKey === "guru")!;
  const shaniTransit = transits.find((t) => t.grahaKey === "shani")!;

  const synthesisHtml = `
    <p class="gochara-p">
      <strong>Cosmic Pulse & Vital Energy:</strong> 
      <strong>Surya (Sun)</strong> is currently transiting your <strong>${suryaTransit.houseNum}${getOrdinal(suryaTransit.houseNum)} House (${suryaTransit.bhavaSanskrit})</strong> in ${suryaTransit.transitRashi}. 
      ${suryaTransit.phala}
    </p>
    <p class="gochara-p">
      <strong>Mind & Emotional Climate:</strong> 
      <strong>Chandra (Moon)</strong> is traversing your <strong>${chandraTransit.houseNum}${getOrdinal(chandraTransit.houseNum)} House (${chandraTransit.bhavaSanskrit})</strong> in ${chandraTransit.transitRashi}. 
      ${chandraTransit.phala}
    </p>
    <p class="gochara-p">
      <strong>Blessings & Karmic Anchors:</strong> 
      The great benefic <strong>Guru (Jupiter)</strong> illuminates your <strong>${guruTransit.houseNum}${getOrdinal(guruTransit.houseNum)} House (${guruTransit.bhavaSanskrit})</strong>, bringing protective wisdom. Concurrently, <strong>Shani (Saturn)</strong>'s presence in your <strong>${shaniTransit.houseNum}${getOrdinal(shaniTransit.houseNum)} House (${shaniTransit.bhavaSanskrit})</strong> highlights the need for enduring discipline and measured patience.
    </p>
  `;

  return {
    userRashi: rashiMeta.name,
    rashiIndex: userRashiIndex,
    highlightBadges: highlights.slice(0, 4),
    synthesisHtml,
    transits,
    remedy,
  };
}

// ── HTMX endpoint: /api/horoscope ─────────────────────────────────────────────
app.post("/api/horoscope", async (c) => {
  const body = await c.req.parseBody();
  const rashiKey = String(body.rashi || "mesh").toLowerCase();
  const day = (String(body.day || "today").toLowerCase()) as DayParam;

  const rashi = RASHI_MAP[rashiKey];
  if (!rashi) {
    return c.html(
      `<div class="error-card"><span>⚠️</span> Invalid rashi selected. Please choose again.</div>`
    );
  }

  let horoscope: string;
  let date: string;

  try {
    const data = await fetchHoroscope(rashi.sign, day);
    horoscope = data.horoscope;
    date = data.date;
  } catch (err) {
    return c.html(
      `<div class="error-card"><span>🌌</span> Could not reach the stars right now. Please try again shortly.</div>`
    );
  }

  const now = new Date();
  const liveGrahas = computeGrahas(now);
  const gochara = analyzeGochara(rashiKey, liveGrahas);

  const lucky = getLucky(rashi.sign, date);
  const elemColor = ELEMENT_COLORS[rashi.element];
  const dayLabel =
    day === "today" ? "Today" : day === "tomorrow" ? "Tomorrow" : "Yesterday";

  const scoreBar = (label: string, val: number, color: string) => `
    <div class="score-row">
      <span class="score-label">${label}</span>
      <div class="score-bar-wrap">
        <div class="score-bar" style="width:${val}%;background:${color}" data-val="${val}"></div>
      </div>
      <span class="score-num">${val}%</span>
    </div>`;

  // Render Gochara Highlight Pills
  const highlightPills = gochara.highlightBadges.map((b) => `
    <span class="gochara-pill pill-${b.type}">
      <span class="pill-icon">${b.icon}</span>
      <span>${b.text}</span>
    </span>
  `).join("");

  // Render Graha Transit Cards
  const transitCards = gochara.transits.map((t) => `
    <div class="gochara-transit-card card-${t.statusType}">
      <div class="gtc-header">
        <div class="gtc-left">
          <span class="gtc-emoji">${t.emoji}</span>
          <div>
            <div class="gtc-name" style="color:${t.color}">${t.name} <span class="gtc-deg">${t.degInRashi}° in ${t.transitRashi}${t.isRetro ? " ℞" : ""}</span></div>
            <div class="gtc-bhava">${t.houseNum}${getOrdinal(t.houseNum)} House · ${t.bhavaSanskrit}</div>
          </div>
        </div>
        <span class="gtc-status badge-${t.statusType}">${t.status}</span>
      </div>
      <div class="gtc-domain"><strong>Significance:</strong> ${t.bhavaDomain}</div>
      <p class="gtc-phala">${t.phala}</p>
    </div>
  `).join("");

  return c.html(`
<div class="result-card">
  <!-- Header -->
  <div class="result-header" style="border-color:${elemColor}">
    <div class="result-emoji">${rashi.emoji}</div>
    <div class="result-title-block">
      <h2 class="result-title">${rashi.sign} <span class="rashi-name">(${rashiKey.charAt(0).toUpperCase() + rashiKey.slice(1)})</span></h2>
      <div class="result-meta">
        <span class="meta-badge" style="background:${elemColor}22;color:${elemColor};border-color:${elemColor}55">${rashi.element}</span>
        <span class="meta-badge">🪐 Ruler: ${rashi.ruler}</span>
        <span class="meta-badge">📅 ${dayLabel} · ${date}</span>
      </div>
    </div>
  </div>

  <!-- Horoscope text -->
  <div class="horoscope-body">
    <div class="stars-icon">✨</div>
    <div class="horoscope-eyebrow">General Daily Reading</div>
    <p class="horoscope-text">${horoscope}</p>
  </div>

  <!-- ── Planetary Transit (Gochara Phala) Deep Explanation ────────────────── -->
  <section class="gochara-section" aria-labelledby="gochara-heading">
    <div class="gochara-header-row">
      <div>
        <div class="gochara-badge">Vedic Gochara System</div>
        <h3 id="gochara-heading" class="gochara-title">Astrological Explanation & Graha Positions</h3>
      </div>
      <span class="gochara-rashi-tag">Reference: ${gochara.userRashi} Rashi</span>
    </div>

    <!-- Live Highlights -->
    <div class="gochara-highlights-wrap">
      ${highlightPills}
    </div>

    <!-- Astrological Synthesis Narrative -->
    <div class="gochara-narrative-box">
      <div class="gn-label">🪐 Why the stars say this for ${rashi.sign} today:</div>
      ${gochara.synthesisHtml}
    </div>

    <!-- Detailed 9-Graha House Transit Cards -->
    <details class="gochara-accordion" open>
      <summary class="gochara-acc-summary">
        <span>Detailed Navagraha Transits from ${gochara.userRashi} (${gochara.transits.length} Grahas)</span>
      </summary>
      <div class="gochara-grid">
        ${transitCards}
      </div>
    </details>
  </section>

  <!-- Lucky section -->
  <div class="lucky-grid">
    <div class="lucky-card">
      <div class="lucky-icon">🔢</div>
      <div class="lucky-value">${lucky.num}</div>
      <div class="lucky-label">Lucky Number</div>
    </div>
    <div class="lucky-card">
      <div class="lucky-icon">🎨</div>
      <div class="lucky-value">${lucky.color}</div>
      <div class="lucky-label">Lucky Color</div>
    </div>
    <div class="lucky-card">
      <div class="lucky-icon">💎</div>
      <div class="lucky-value">${rashi.traits[0]}</div>
      <div class="lucky-label">Key Trait</div>
    </div>
  </div>

  <!-- Life Energies Scores -->
  <div class="scores-section">
    <h3 class="scores-title">Life Energies</h3>
    ${scoreBar("❤️ Love & Harmony", lucky.scores.love, "#e91e63")}
    ${scoreBar("💼 Career & Ambition", lucky.scores.career, "#2196f3")}
    ${scoreBar("🌿 Health & Vitality", lucky.scores.health, "#4caf50")}
  </div>

  <!-- ── Vedic Upaya & Mantras ────────────────────────────────────────────── -->
  <div class="upaya-card">
    <div class="upaya-header">
      <span class="upaya-icon">🪔</span>
      <div>
        <h4 class="upaya-title">Vedic Jyotishi Upaya (Remedy & Mantra)</h4>
        <div class="upaya-sub">Prescribed for ${gochara.userRashi} · Lord: ${rashi.ruler} (${gochara.remedy.deity})</div>
      </div>
    </div>
    <div class="mantra-box">
      <div class="mantra-deva">${gochara.remedy.mantra}</div>
      <div class="mantra-eng">${gochara.remedy.mantraEng}</div>
    </div>
    <div class="upaya-body">
      <p class="upaya-text"><strong>Daily Practice:</strong> ${gochara.remedy.upaya}</p>
      <div class="upaya-tags">
        <span class="upaya-tag">🎨 Auspicious Colors: ${gochara.remedy.color}</span>
        <span class="upaya-tag">⚡ Sacred Metal: ${gochara.remedy.metal}</span>
      </div>
    </div>
  </div>

  <!-- Traits -->
  <div class="traits-section">
    ${rashi.traits.map((t) => `<span class="trait-chip">${t}</span>`).join("")}
  </div>
</div>
  `);
});

// ── GET /api/grahas — Live Navagraha positions ────────────────────────────────
app.get("/api/grahas", (c) => {
  const now    = new Date();
  const grahas = computeGrahas(now);

  // Build a map: rashiIndex → grahas in that rashi
  const rashiGrahas: Map<number, GrahaPosition[]> = new Map();
  for (let i = 0; i < 12; i++) rashiGrahas.set(i, []);
  for (const g of grahas) rashiGrahas.get(g.rashiIndex)!.push(g);

  const updatedAt = now.toLocaleTimeString("en-IN", {
    hour: "2-digit", minute: "2-digit", second: "2-digit",
    timeZone: "Asia/Kolkata",
  });

  // Render each rashi cell
  const rashiCells = RASHI_LIST.map((r, i) => {
    const inThis = rashiGrahas.get(i) ?? [];
    const planets = inThis.map(g => `
      <div class="graha-chip" style="--gc:#${g.color.slice(1)}" title="${g.name} — ${g.degInRashi}° in ${r.name}${g.isRetro ? ' (retrograde)' : ''}">
        <span class="gc-emoji">${g.emoji}</span>
        <span class="gc-name">${g.name}</span>
        <span class="gc-deg">${g.degInRashi}°${g.isRetro ? " ℞" : ""}</span>
      </div>`).join("");

    const isOccupied = inThis.length > 0;
    return `
      <div class="chakra-cell ${isOccupied ? "occupied" : ""}">
        <div class="cc-header">
          <span class="cc-emoji">${r.emoji}</span>
          <div class="cc-names">
            <span class="cc-name">${r.name}</span>
            <span class="cc-en">${r.en}</span>
          </div>
          <span class="cc-num">${i + 1}</span>
        </div>
        <div class="cc-planets">${planets || '<span class="cc-empty">—</span>'}</div>
      </div>`;
  }).join("");

  // Planet legend
  const legend = grahas.map(g => `
    <div class="legend-item">
      <span class="legend-emoji">${g.emoji}</span>
      <span class="legend-name">${g.name}</span>
      <span class="legend-pos">${RASHI_LIST[g.rashiIndex].name} ${g.degInRashi}°${g.isRetro ? " ℞" : ""}</span>
    </div>`).join("");

  return c.html(`
<div class="chakra-wrapper">
  <div class="chakra-topbar">
    <span class="chakra-title">🪐 Navagraha Sthiti — Live Positions</span>
    <span class="chakra-updated">Updated: ${updatedAt} IST</span>
  </div>
  <div class="chakra-grid">${rashiCells}</div>
  <details class="graha-legend">
    <summary class="legend-summary">View all Graha positions</summary>
    <div class="legend-grid">${legend}</div>
  </details>
</div>
  `);
});

// ── Janma Kundli (Birth Chart) Calculation & Rendering Engine ───────────────

const NAKSHATRAS = [
  { name: "Ashwini", ruler: "Ketu", deity: "Ashwini Kumaras" },
  { name: "Bharani", ruler: "Venus", deity: "Yama" },
  { name: "Krittika", ruler: "Sun", deity: "Agni" },
  { name: "Rohini", ruler: "Moon", deity: "Brahma" },
  { name: "Mrigashira", ruler: "Mars", deity: "Soma" },
  { name: "Ardra", ruler: "Rahu", deity: "Rudra" },
  { name: "Punarvasu", ruler: "Jupiter", deity: "Aditi" },
  { name: "Pushya", ruler: "Saturn", deity: "Brihaspati" },
  { name: "Ashlesha", ruler: "Mercury", deity: "Nagas" },
  { name: "Magha", ruler: "Ketu", deity: "Pitris" },
  { name: "Purva Phalguni", ruler: "Venus", deity: "Bhaga" },
  { name: "Uttara Phalguni", ruler: "Sun", deity: "Aryaman" },
  { name: "Hasta", ruler: "Moon", deity: "Savitar" },
  { name: "Chitra", ruler: "Mars", deity: "Tvashtar" },
  { name: "Swati", ruler: "Rahu", deity: "Vayu" },
  { name: "Vishakha", ruler: "Jupiter", deity: "Indra & Agni" },
  { name: "Anuradha", ruler: "Saturn", deity: "Mitra" },
  { name: "Jyeshtha", ruler: "Mercury", deity: "Indra" },
  { name: "Mula", ruler: "Ketu", deity: "Nirriti" },
  { name: "Purva Ashadha", ruler: "Venus", deity: "Apas" },
  { name: "Uttara Ashadha", ruler: "Sun", deity: "Vishvadevas" },
  { name: "Shravana", ruler: "Moon", deity: "Vishnu" },
  { name: "Dhanishta", ruler: "Mars", deity: "Eight Vasus" },
  { name: "Shatabhisha", ruler: "Rahu", deity: "Varuna" },
  { name: "Purva Bhadrapada", ruler: "Jupiter", deity: "Aja Ekapada" },
  { name: "Uttara Bhadrapada", ruler: "Saturn", deity: "Ahirbudhnya" },
  { name: "Revati", ruler: "Mercury", deity: "Pushan" },
];

function getNakshatra(siderealDeg: number): { name: string; ruler: string; deity: string; pada: number } {
  const arc = 360 / 27; // 13.333333°
  const padaArc = arc / 4; // 3.333333°
  const index = Math.floor(siderealDeg / arc) % 27;
  const rem = siderealDeg % arc;
  const pada = Math.floor(rem / padaArc) + 1;
  const nak = NAKSHATRAS[index];
  return { ...nak, pada };
}

function computeLagna(utcDate: Date, lat: number, lon: number): { sidereal: number; rashiIndex: number; degInRashi: string } {
  const jd = julianDate(utcDate);
  const D = jd - J2000_JD;
  const gmst = mod360(280.46061837 + 360.98564736629 * D);
  const lst = mod360(gmst + lon);

  const T = D / 36525;
  const eps = 23.43929111 - 0.0130042 * T;

  const epsRad = (eps * Math.PI) / 180;
  const phiRad = (lat * Math.PI) / 180;
  const lstRad = (lst * Math.PI) / 180;

  const y = -Math.cos(lstRad);
  const x = Math.sin(lstRad) * Math.cos(epsRad) + Math.tan(phiRad) * Math.sin(epsRad);

  let ascTropical = Math.atan2(y, x) * (180 / Math.PI);
  ascTropical = mod360(ascTropical);

  const ayanamsa = AYANAMSA_J2000 + AYANAMSA_RATE * D;
  const sidereal = mod360(ascTropical - ayanamsa);
  const rashiIndex = Math.floor(sidereal / 30);
  const degInRashi = (sidereal % 30).toFixed(2);

  return { sidereal, rashiIndex, degInRashi };
}

// Generate North Indian Kundli SVG
function renderNorthIndianKundliSvg(
  lagnaRashiIndex: number,
  planetsByHouse: Map<number, { name: string; emoji: string; color: string; deg: string }[]>
): string {
  const houseCoords = [
    { num: 1,  rx: 210, ry: 75,  px: 210, py: 115 },
    { num: 2,  rx: 110, ry: 45,  px: 110, py: 70  },
    { num: 3,  rx: 60,  ry: 95,  px: 65,  py: 120 },
    { num: 4,  rx: 115, ry: 210, px: 115, py: 235 },
    { num: 5,  rx: 60,  ry: 325, px: 65,  py: 300 },
    { num: 6,  rx: 110, ry: 375, px: 110, py: 350 },
    { num: 7,  rx: 210, ry: 345, px: 210, py: 305 },
    { num: 8,  rx: 310, ry: 375, px: 310, py: 350 },
    { num: 9,  rx: 360, ry: 325, px: 355, py: 300 },
    { num: 10, rx: 305, ry: 210, px: 305, py: 235 },
    { num: 11, rx: 360, ry: 95,  px: 355, py: 120 },
    { num: 12, rx: 310, ry: 45,  px: 310, py: 70  },
  ];

  const svgElements: string[] = [];

  svgElements.push(`
    <rect x="10" y="10" width="400" height="400" fill="rgba(18, 10, 36, 0.75)" stroke="#eab308" stroke-width="2"/>
    <line x1="10" y1="10" x2="410" y2="410" stroke="#ca8a04" stroke-width="1.5" opacity="0.75"/>
    <line x1="410" y1="10" x2="10" y2="410" stroke="#ca8a04" stroke-width="1.5" opacity="0.75"/>
    <polygon points="210,10 410,210 210,410 10,210" fill="none" stroke="#eab308" stroke-width="2"/>
  `);

  for (const h of houseCoords) {
    const signNum = ((lagnaRashiIndex + h.num - 1) % 12) + 1;
    svgElements.push(`
      <text x="${h.rx}" y="${h.ry}" fill="#fde047" font-size="11" font-weight="700" text-anchor="middle" font-family="'Cinzel', serif">${signNum}</text>
    `);

    const planets = planetsByHouse.get(h.num) || [];
    if (planets.length > 0) {
      planets.forEach((p, idx) => {
        const yOff = h.py + (idx - (planets.length - 1) / 2) * 14;
        svgElements.push(`
          <text x="${h.px}" y="${yOff}" fill="${p.color}" font-size="10" font-weight="600" text-anchor="middle" font-family="'Inter', sans-serif">
            ${p.emoji} ${p.name.slice(0, 2)} <tspan fill="#94a3b8" font-size="8">${Math.floor(parseFloat(p.deg))}°</tspan>
          </text>
        `);
      });
    }
  }

  return `
    <div class="kundli-svg-wrap">
      <svg viewBox="0 0 420 420" class="kundli-svg" aria-label="North Indian Vedic Birth Chart">
        ${svgElements.join("")}
      </svg>
      <div class="kundli-caption">Traditional North Indian Rashi Chart (D1 Kundli)</div>
    </div>
  `;
}

// Detect Classical Vedic Yogas
function detectNatalYogas(
  planets: { name: string; house: number; rashiIndex: number }[]
): { name: string; type: "raja" | "dhana" | "auspicious"; desc: string }[] {
  const yogas: { name: string; type: "raja" | "dhana" | "auspicious"; desc: string }[] = [];

  const jup = planets.find((p) => p.name === "Guru");
  const moon = planets.find((p) => p.name === "Chandra");
  const sun = planets.find((p) => p.name === "Surya");
  const merc = planets.find((p) => p.name === "Budha");
  const mars = planets.find((p) => p.name === "Mangal");
  const ven = planets.find((p) => p.name === "Shukra");
  const sat = planets.find((p) => p.name === "Shani");

  // Gajakesari Yoga: Jupiter in Kendra (1, 4, 7, 10) from Moon
  if (jup && moon) {
    const diff = ((jup.house - moon.house + 12) % 12) + 1;
    if ([1, 4, 7, 10].includes(diff)) {
      yogas.push({
        name: "Gajakesari Yoga 🐘",
        type: "raja",
        desc: "Jupiter in angular Kendra from Moon. Endows noble character, enduring public respect, wisdom, and leadership stature.",
      });
    }
  }

  // Budhaditya Yoga: Sun and Mercury together
  if (sun && merc && sun.rashiIndex === merc.rashiIndex) {
    yogas.push({
      name: "Budhaditya Yoga ☀️☿",
      type: "auspicious",
      desc: "Sun and Mercury conjunction. Bestows sharp analytical acumen, articulate speech, intellectual brilliance, and executive agility.",
    });
  }

  // Chandra-Mangal Yoga: Moon and Mars together
  if (moon && mars && moon.rashiIndex === mars.rashiIndex) {
    yogas.push({
      name: "Chandra-Mangal Yoga 🌙♂",
      type: "dhana",
      desc: "Moon and Mars conjunction. Generates formidable financial drive, real-estate prosperity, and energetic self-enterprise.",
    });
  }

  // Pancha Mahapurusha Yogas (Exalted or Swakshetra in Kendra from Lagna)
  if (mars && [1, 4, 7, 10].includes(mars.house) && [0, 7, 9].includes(mars.rashiIndex)) {
    yogas.push({
      name: "Ruchaka Mahapurusha Yoga ⚔️",
      type: "raja",
      desc: "Mars dignified in Kendra. Grants heroic courage, athletic vitality, victorious leadership, and high technical authority.",
    });
  }
  if (merc && [1, 4, 7, 10].includes(merc.house) && [2, 5].includes(merc.rashiIndex)) {
    yogas.push({
      name: "Bhadra Mahapurusha Yoga 📜",
      type: "raja",
      desc: "Mercury dignified in Kendra. Bestows scholarly eloquence, commercial mastery, diplomatic wit, and longevity.",
    });
  }
  if (jup && [1, 4, 7, 10].includes(jup.house) && [3, 8, 11].includes(jup.rashiIndex)) {
    yogas.push({
      name: "Hamsa Mahapurusha Yoga 🦢",
      type: "raja",
      desc: "Jupiter dignified in Kendra. Blesses with pure spiritual ethics, reverence from society, institutional power, and inner grace.",
    });
  }
  if (ven && [1, 4, 7, 10].includes(ven.house) && [1, 6, 11].includes(ven.rashiIndex)) {
    yogas.push({
      name: "Malavya Mahapurusha Yoga 💎",
      type: "raja",
      desc: "Venus dignified in Kendra. Bestows aesthetic elegance, luxurious vehicle and property comforts, magnetic allure, and marital bliss.",
    });
  }
  if (sat && [1, 4, 7, 10].includes(sat.house) && [6, 9, 10].includes(sat.rashiIndex)) {
    yogas.push({
      name: "Sasa Mahapurusha Yoga ⚖️",
      type: "raja",
      desc: "Saturn dignified in Kendra. Yields supreme endurance, disciplined authority over masses, institutional mastery, and deep perseverance.",
    });
  }

  if (yogas.length === 0) {
    yogas.push({
      name: "Shubha Graha Sthiti ✨",
      type: "auspicious",
      desc: "Balanced planetary configuration. Planetary energies provide progressive opportunities through mindful self-effort and alignment.",
    });
  }

  return yogas;
}

// ── POST /api/kundli — Complete Janma Kundli & Transit Analysis ─────────────
app.post("/api/kundli", async (c) => {
  const body = await c.req.parseBody();
  const name = String(body.name || "Seeker").trim();
  const dob = String(body.dob || "2000-01-01");
  const tob = String(body.tob || "12:00");
  const city = String(body.city || "New Delhi, India");
  const lat = parseFloat(String(body.lat || "28.6139"));
  const lon = parseFloat(String(body.lon || "77.2090"));
  const tz = parseFloat(String(body.tz || "5.5"));

  const [year, month, day] = dob.split("-").map((x) => parseInt(x, 10));
  const [hour, min] = tob.split(":").map((x) => parseInt(x, 10));

  if (isNaN(year) || isNaN(month) || isNaN(day) || isNaN(hour) || isNaN(min)) {
    return c.html(`<div class="error-card"><span>⚠️</span> Please enter valid birth date and time values.</div>`);
  }

  const localMs = Date.UTC(year, month - 1, day, hour, min, 0);
  const utcMs = localMs - tz * 3600000;
  const birthUtc = new Date(utcMs);

  const natalGrahas = computeGrahas(birthUtc);
  const lagna = computeLagna(birthUtc, lat, lon);

  const lagnaRashi = RASHI_LIST[lagna.rashiIndex];
  const lagnaLord = RASHI_MAP[lagnaRashi.key].ruler;

  const moon = natalGrahas.find((g) => g.name === "Chandra")!;
  const moonRashi = RASHI_LIST[moon.rashiIndex];
  const moonNak = getNakshatra(moon.sidereal);

  const planetsByHouse = new Map<number, { name: string; emoji: string; color: string; deg: string }[]>();
  for (let i = 1; i <= 12; i++) planetsByHouse.set(i, []);

  const natalPlanetDetails = natalGrahas.map((g) => {
    const house = ((g.rashiIndex - lagna.rashiIndex + 12) % 12) + 1;
    const nak = getNakshatra(g.sidereal);
    planetsByHouse.get(house)!.push({ name: g.name, emoji: g.emoji, color: g.color, deg: g.degInRashi });
    return { ...g, house, nak };
  });

  const svgChart = renderNorthIndianKundliSvg(lagna.rashiIndex, planetsByHouse);
  const yogas = detectNatalYogas(natalPlanetDetails.map((p) => ({ name: p.name, house: p.house, rashiIndex: p.rashiIndex })));

  const liveNow = new Date();
  const liveGrahas = computeGrahas(liveNow);
  const gocharaFromMoon = analyzeGochara(moonRashi.key, liveGrahas);

  const transitLagnaHighlights: string[] = [];
  liveGrahas.forEach((g) => {
    const houseFromLagna = ((g.rashiIndex - lagna.rashiIndex + 12) % 12) + 1;
    const bhava = BHAVA_INFO[houseFromLagna - 1];
    if (g.name === "Guru") {
      transitLagnaHighlights.push(`♃ Live Jupiter is transiting your natal <strong>${houseFromLagna}${getOrdinal(houseFromLagna)} House (${bhava.sanskrit})</strong>, expanding ${bhava.domain}.`);
    } else if (g.name === "Shani") {
      transitLagnaHighlights.push(`♄ Live Saturn is transiting your natal <strong>${houseFromLagna}${getOrdinal(houseFromLagna)} House (${bhava.sanskrit})</strong>, instilling duty and restructuring.`);
    } else if (g.name === "Surya") {
      transitLagnaHighlights.push(`☀️ Live Sun highlights your natal <strong>${houseFromLagna}${getOrdinal(houseFromLagna)} House (${bhava.sanskrit})</strong>, bringing focus and vital energy.`);
    }
  });

  const bhavaCards = BHAVA_INFO.map((b) => {
    const rIndex = (lagna.rashiIndex + b.num - 1) % 12;
    const rSign = RASHI_LIST[rIndex];
    const rLord = RASHI_MAP[rSign.key].ruler;
    const residentPlanets = natalPlanetDetails.filter((p) => p.house === b.num);

    const residentText = residentPlanets.length > 0
      ? residentPlanets.map((p) => `<span class="bhava-graha-tag" style="--bgc:${p.color}">${p.emoji} ${p.name} (${p.degInRashi}°)</span>`).join(" ")
      : `<span class="bhava-empty">No natal planets (Influenced directly by Lord ${rLord})</span>`;

    return `
      <div class="bhava-detail-card">
        <div class="bdc-top">
          <div class="bdc-title">
            <span class="bdc-num">${b.num}</span>
            <div>
              <h4 class="bdc-name">${b.name} · ${b.sanskrit}</h4>
              <div class="bdc-sign">${rSign.emoji} ${rSign.name} (${rSign.en}) · Lord: <strong>${rLord}</strong></div>
            </div>
          </div>
        </div>
        <div class="bdc-domain"><strong>Life Domain:</strong> ${b.domain}</div>
        <div class="bdc-planets"><strong>Natal Occupants:</strong> ${residentText}</div>
      </div>
    `;
  }).join("");

  const lagnaRemedy = RASHI_REMEDIES[lagnaRashi.key] || RASHI_REMEDIES.mesh;
  const moonRemedy = RASHI_REMEDIES[moonRashi.key] || RASHI_REMEDIES.kark;

  const latFormatted = `${Math.abs(lat).toFixed(4)}°${lat >= 0 ? "N" : "S"}`;
  const lonFormatted = `${Math.abs(lon).toFixed(4)}°${lon >= 0 ? "E" : "W"}`;

  return c.html(`
<div class="result-card kundli-result-card">
  <!-- Birth Header -->
  <div class="kundli-header">
    <div class="kh-top">
      <div>
        <div class="kh-eyebrow">Janma Kundli · Vedic Birth Blueprint</div>
        <h2 class="kh-name">${name}</h2>
        <div class="kh-meta">
          <span>📅 ${dob} at ${tob}</span>
          <span>📍 ${city} (${latFormatted}, ${lonFormatted})</span>
          <span>🌐 Timezone: UTC${tz >= 0 ? "+" + tz : tz}</span>
        </div>
      </div>
      <div class="kh-badge-box">
        <div class="triad-badge">
          <span class="tb-label">Rising Lagna (Ascendant)</span>
          <span class="tb-val">${lagnaRashi.emoji} ${lagnaRashi.name} (${lagna.degInRashi}°)</span>
        </div>
        <div class="triad-badge">
          <span class="tb-label">Chandra Rashi (Moon Sign)</span>
          <span class="tb-val">${moonRashi.emoji} ${moonRashi.name} (${moon.degInRashi}°)</span>
        </div>
        <div class="triad-badge">
          <span class="tb-label">Janma Nakshatra</span>
          <span class="tb-val">✨ ${moonNak.name} (Pada ${moonNak.pada})</span>
        </div>
      </div>
    </div>
  </div>

  <!-- Chart & Planetary Table Section -->
  <div class="chart-and-table-grid">
    <div class="chart-col">
      ${svgChart}
    </div>
    <div class="table-col">
      <h3 class="col-title">Natal Planetary Placements</h3>
      <div class="natal-table-wrap">
        <table class="natal-table">
          <thead>
            <tr>
              <th>Graha</th>
              <th>Rashi</th>
              <th>Degree</th>
              <th>Bhava</th>
              <th>Nakshatra</th>
            </tr>
          </thead>
          <tbody>
            <tr class="lagna-tr">
              <td><strong>Lagna</strong></td>
              <td>${lagnaRashi.emoji} ${lagnaRashi.name}</td>
              <td>${lagna.degInRashi}°</td>
              <td>1st House</td>
              <td>—</td>
            </tr>
            ${natalPlanetDetails.map((p) => `
              <tr>
                <td><span style="color:${p.color}">${p.emoji} ${p.name}</span></td>
                <td>${RASHI_LIST[p.rashiIndex].emoji} ${RASHI_LIST[p.rashiIndex].name}</td>
                <td>${p.degInRashi}°</td>
                <td><span class="house-pill">${p.house}${getOrdinal(p.house)} House</span></td>
                <td>${p.nak.name} (${p.nak.pada})</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ── Vedic Yogas Detected in Birth Chart ──────────────────────────────── -->
  <section class="kundli-section" aria-labelledby="yogas-title">
    <div class="section-label">Auspicious Formations</div>
    <h3 id="yogas-title" class="sub-title">Vedic Yogas Formed at Birth</h3>
    <div class="yogas-grid">
      ${yogas.map((y) => `
        <div class="yoga-card yoga-${y.type}">
          <div class="yoga-header">
            <h4 class="yoga-name">${y.name}</h4>
            <span class="yoga-tag tag-${y.type}">${y.type.toUpperCase()} YOGA</span>
          </div>
          <p class="yoga-desc">${y.desc}</p>
        </div>
      `).join("")}
    </div>
  </section>

  <!-- ── Live Gochara Transits on Your Birth Blueprint ───────────────────── -->
  <section class="kundli-section" aria-labelledby="transits-overlay-title">
    <div class="section-label">Real-Time Cosmic Activation</div>
    <h3 id="transits-overlay-title" class="sub-title">Live Gochara (Transits) Over Your Natal Houses</h3>
    <div class="transit-overlay-box">
      <p class="overlay-intro">
        Your <strong>Janma Kundli</strong> is the blueprint; right now, the moving planets in the sky are triggering specific houses in your chart.
      </p>
      <div class="transit-triggers-list">
        ${transitLagnaHighlights.map((t) => `<div class="trigger-item">${t}</div>`).join("")}
      </div>
      <div class="moon-transit-highlight">
        <strong>Moon-Sign Transit Note:</strong> Live planets are transiting relative to your birth Moon (<strong>${moonRashi.name}</strong>).
        <div class="moon-gochara-badges">
          ${gocharaFromMoon.highlightBadges.map((b) => `<span class="gochara-pill pill-${b.type}">${b.icon} ${b.text}</span>`).join("")}
        </div>
      </div>
    </div>
  </section>

  <!-- ── 12 Bhavas Comprehensive Breakdown ────────────────────────────────── -->
  <details class="bhavas-accordion" open>
    <summary class="bhavas-summary">
      <span>🏛️ Detailed Breakdown of Your 12 Life Bhavas (Houses)</span>
    </summary>
    <div class="bhavas-grid">
      ${bhavaCards}
    </div>
  </details>

  <!-- ── Personalized Vedic Upayas ────────────────────────────────────────── -->
  <section class="kundli-section" aria-labelledby="upaya-title">
    <div class="section-label">Prescribed Vedic Upayas</div>
    <h3 id="upaya-title" class="sub-title">Remedies for Lagna & Chandra Lords</h3>
    <div class="upaya-dual-grid">
      <div class="upaya-card">
        <div class="upaya-header">
          <span class="upaya-icon">🪔</span>
          <div>
            <h4 class="upaya-title">Lagna Lord Upaya (${lagnaLord})</h4>
            <div class="upaya-sub">For physical vitality, career direction, and aura strength</div>
          </div>
        </div>
        <div class="mantra-box">
          <div class="mantra-deva">${lagnaRemedy.mantra}</div>
          <div class="mantra-eng">${lagnaRemedy.mantraEng}</div>
        </div>
        <p class="upaya-text"><strong>Guidance:</strong> ${lagnaRemedy.upaya}</p>
        <div class="upaya-tags">
          <span class="upaya-tag">🎨 Auspicious: ${lagnaRemedy.color}</span>
          <span class="upaya-tag">⚡ Metal: ${lagnaRemedy.metal}</span>
        </div>
      </div>

      <div class="upaya-card">
        <div class="upaya-header">
          <span class="upaya-icon">🌙</span>
          <div>
            <h4 class="upaya-title">Moon Lord Upaya (${RASHI_MAP[moonRashi.key].ruler})</h4>
            <div class="upaya-sub">For peace of mind, intuition, and emotional resilience</div>
          </div>
        </div>
        <div class="mantra-box">
          <div class="mantra-deva">${moonRemedy.mantra}</div>
          <div class="mantra-eng">${moonRemedy.mantraEng}</div>
        </div>
        <p class="upaya-text"><strong>Guidance:</strong> ${moonRemedy.upaya}</p>
        <div class="upaya-tags">
          <span class="upaya-tag">🎨 Auspicious: ${moonRemedy.color}</span>
          <span class="upaya-tag">⚡ Metal: ${moonRemedy.metal}</span>
        </div>
      </div>
    </div>
  </section>
</div>
  `);
});

if (process.env.NODE_ENV === "production") {
  app.use("/assets/*", serveStatic({ root: "./dist" }));
  app.use("/hero-bg.jpg", serveStatic({ root: "./public" }));
  app.use(
    "/*",
    serveStatic({ root: "./dist", rewriteRequestPath: () => "/index.html" })
  );
}

const PORT = parseInt(process.env.PORT || "3000", 10);
serve({ fetch: app.fetch, port: PORT }, () => {
  console.log(`\n🔮 Jyotishi server running → http://localhost:${PORT}\n`);
});
