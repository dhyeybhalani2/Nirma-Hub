import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class QuestionItem {
  final String title;
  final List<String> badges;
  final String years;
  final List<Map<String, String>> links;
  final String answer;
  final String formula;

  QuestionItem({
    required this.title,
    required this.badges,
    required this.years,
    required this.links,
    required this.answer,
    required this.formula,
  });
}

class UnitSection {
  final String title;
  final List<QuestionItem> questions;

  UnitSection({
    required this.title,
    required this.questions,
  });
}

class SubjectItem {
  final String name;
  final String code;
  final String semester;
  final int topicCount;
  final List<Color> gradient;
  final IconData icon;
  final List<String> stats;
  final List<UnitSection> units;

  SubjectItem({
    required this.name,
    required this.code,
    required this.semester,
    required this.topicCount,
    required this.gradient,
    required this.icon,
    required this.stats,
    required this.units,
  });
}

final List<SubjectItem> parsedSubjectsData = [
  SubjectItem(
    name: "Environmental Science",
    code: "1CL501CC25",
    semester: "Semester 1",
    topicCount: 51,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.globe,
    stats: ["📘 4 Modules", "🔢 51 Topics"],
    units: [
      UnitSection(
        title: "1. Ecology, Atmosphere & Energy",
        questions: [
          QuestionItem(
            title: "Build a graph for (i) pressure vs altitude (ii) temperature vs altitude showing layers. Summarize both.",
            badges: ["Sketch", "High Yield"],
            years: "Apr 25 July 25",
            links: [
          {"label": "Pg 10", "url": "imp_pdf/env_science/1CL501.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Stratosphere role. Describe formation/deformation of Ozone layer with reactions.",
            badges: [],
            years: "July 25",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/env_science/1CL501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain atmosphere components. Distinguish between Atmosphere and Lithosphere.",
            badges: [],
            years: "July 24 Dec 23 Feb 24",
            links: [
          {"label": "Pg 8", "url": "imp_pdf/env_science/1CL501.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Illustrate environment components (Lithosphere/Hydrosphere/Biosphere) with flow diagram.",
            badges: [],
            years: "July 25 May 24 Feb 24",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/env_science/1CL501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss present energy resource scenario in India and challenges.",
            badges: [],
            years: "Apr 25",
            links: [
          {"label": "Pg 10", "url": "imp_pdf/env_science/1CL501.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "List energy demanding activities in urban areas and solutions for urban energy problems.",
            badges: ["High Yield"],
            years: "July 25 May 24 Aug 23",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/env_science/1CL501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Distinguish: Commercial vs Non-commercial / Primary vs Secondary energy.",
            badges: [],
            years: "May 24 Dec 23 June 23 Aug 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/env_science/1CL501.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Recommend ways to redesign urban planning for energy equity.",
            badges: ["Rare"],
            years: "Feb 25",
            links: [
          {"label": "Pg 14", "url": "imp_pdf/env_science/1CL501.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss relationship between energy and environment with examples.",
            badges: [],
            years: "Dec 24",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Biodiversity. Necessity for survival, hotspots, causes of loss.",
            badges: ["High Yield"],
            years: "Dec 24 Feb 24 Aug 23 June 23",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Justify \"Environmental Science is Multidisciplinary\". Role of Math/Stats/CS.",
            badges: [],
            years: "Feb 25 June 23 Aug 23",
            links: [
          {"label": "Pg 4", "url": "imp_pdf/env_science/1CL501.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compare Formal vs Informal education. Public awareness need.",
            badges: [],
            years: "Dec 24 May 24",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "2. Pollution & Waste Management",
        questions: [
          QuestionItem(
            title: "Explain Eutrophication with neat sketch (Process/Effects/Control).",
            badges: ["Sketch", "Top Repeat"],
            years: "July 25 Dec 23 Aug 23",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/env_science/1CL501.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define water pollution. Explain Oxygen Sag Curve outlining zones.",
            badges: ["Curve", "Top Repeat"],
            years: "Feb 25 Aug 23",
            links: [
          {"label": "Pg 14", "url": "imp_pdf/env_science/1CL501.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain different Zones of Purification of stream with neat sketch.",
            badges: [],
            years: "Apr 25 Feb 24",
            links: [
          {"label": "Pg 11", "url": "imp_pdf/env_science/1CL501.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain terms: Synergism and Algal Bloom.",
            badges: ["Rare Terms"],
            years: "Feb 24 Aug 23",
            links: [
          {"label": "Pg 22", "url": "imp_pdf/env_science/1CL501.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss measures to prevent ground water pollution.",
            badges: ["Rare"],
            years: "Aug 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/env_science/1CL501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is E-waste? Sources, growth, impacts, urban mining, disposal.",
            badges: ["High Yield"],
            years: "Apr 25 Dec 24 Dec 23 June 23",
            links: [
          {"label": "Pg 11", "url": "imp_pdf/env_science/1CL501.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Classify plastics per PWM Rules 2016. Symbols, examples, reuse.",
            badges: [],
            years: "July 24 Dec 23 Feb 24",
            links: [
          {"label": "Pg 8", "url": "imp_pdf/env_science/1CL501.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is domestic bio-composting? Steps & structure sketch.",
            badges: ["Sketch"],
            years: "Apr 25 June 23",
            links: [
          {"label": "Pg 11", "url": "imp_pdf/env_science/1CL501.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain C&D Waste (Construction & Demolition) reuse.",
            badges: ["Rare"],
            years: "Aug 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/env_science/1CL501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss 5Rs concept / Zero Waste Lifestyle.",
            badges: [],
            years: "May 24 Dec 23 Aug 23",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/env_science/1CL501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Wet Scrubber to control air pollution with neat sketch.",
            badges: ["Sketch", "Rare"],
            years: "July 25",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/env_science/1CL501.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss noise measurement. List limits under Noise Rules 2000.",
            badges: [],
            years: "May 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/env_science/1CL501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain sources/effects of Radioactive waste. Safe disposal.",
            badges: ["Repeat"],
            years: "Dec 24 May 24 June 23",
            links: [
          {"label": "Pg 13", "url": "imp_pdf/env_science/1CL501.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "List control measures of Thermal Pollution (with sketches). Impact on aquatic life.",
            badges: [],
            years: "Dec 24 Feb 25 June 23",
            links: [
          {"label": "Pg 13", "url": "imp_pdf/env_science/1CL501.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compare Radioactive Decay and Radioactive Waste.",
            badges: ["Rare"],
            years: "Aug 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/env_science/1CL501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Soil Pollution. Causes, effects, and control measures.",
            badges: [],
            years: "Apr 25 Feb 25 Dec 23",
            links: [
          {"label": "Pg 14", "url": "imp_pdf/env_science/1CL501.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "3. Sustainability & Impact Assessment",
        questions: [
          QuestionItem(
            title: "Explain contents of EIA report in sequence. (Also: objectives/steps).",
            badges: ["Top Repeat"],
            years: "June 23 Feb 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/env_science/1CL501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate effectiveness of EIA in India (Balancing development vs protection).",
            badges: [],
            years: "Dec 24",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define EIA, steps/process, and significance in environmental planning.",
            badges: [],
            years: "Apr 25 May 24 Aug 23",
            links: [
          {"label": "Pg 10", "url": "imp_pdf/env_science/1CL501.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the surveys and analysis required to conduct EIA.",
            badges: [],
            years: "Dec 23",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/env_science/1CL501.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Conclude Carbon Footprint and Carbon Credits. How do they work?",
            badges: ["High Repeat"],
            years: "Apr 25 July 24 Feb 24",
            links: [
          {"label": "Pg 10", "url": "imp_pdf/env_science/1CL501.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Analyze challenges in Carbon Trading. Ethical/Economic implications.",
            badges: [],
            years: "Feb 25 Dec 24 June 23",
            links: [
          {"label": "Pg 15", "url": "imp_pdf/env_science/1CL501.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Carbon Tax and hurdles in implementation.",
            badges: ["Rare"],
            years: "Dec 23",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/env_science/1CL501.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss role of CDM (Clean Development Mechanism).",
            badges: ["Rare"],
            years: "Feb 25",
            links: [
          {"label": "Pg 15", "url": "imp_pdf/env_science/1CL501.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Identify 12 SDGs. Discuss SDG-6 (Water) and SDG-11 (Cities).",
            badges: ["Repeat"],
            years: "July 25 Apr 25 July 24",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/env_science/1CL501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Green Technology (branches/examples) and Green Building integration.",
            badges: [],
            years: "July 25 Dec 24 Aug 23",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/env_science/1CL501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Analyze Life-Cycle Assessment (LCA) and Ecosystem Valuation.",
            badges: [],
            years: "Dec 24 Dec 23",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "How can Circular Economy address resource scarcity? (vs Linear).",
            badges: [],
            years: "Feb 25 Dec 23",
            links: [
          {"label": "Pg 14", "url": "imp_pdf/env_science/1CL501.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain EPI (Environmental Performance Index) and highlights of EPI 2022.",
            badges: [],
            years: "July 25 June 23",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/env_science/1CL501.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "4. Social Issues, Ethics & Acts",
        questions: [
          QuestionItem(
            title: "Utilize concept of RWH and explain roof-top components with neat sketch.",
            badges: ["Sketch", "Top Repeat"],
            years: "July 25 Dec 24 June 23",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/env_science/1CL501.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Classify and explain various types of filtration systems in RWH (with sketches).",
            badges: [],
            years: "Dec 24 Aug 23",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain how RWH is a necessity of today. Discuss methods.",
            badges: [],
            years: "July 24 Feb 24",
            links: [
          {"label": "Pg 9", "url": "imp_pdf/env_science/1CL501.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain objectives & features of Environment (Protection) Act, 1986. Effectiveness.",
            badges: [],
            years: "July 25 Feb 25 May 24",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/env_science/1CL501.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain objectives of Water Act 1974 and role of individual.",
            badges: [],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "Pg 11", "url": "imp_pdf/env_science/1CL501.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Examine role of Wildlife Protection Act 1972. List penalties.",
            badges: [],
            years: "Dec 24 Dec 23 June 23",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/env_science/1CL501.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write objectives/measures of Forest Conservation Act.",
            badges: [],
            years: "June 23 Feb 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/env_science/1CL501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Resettlement and Rehabilitation. Discuss major concerns of displaced populations.",
            badges: [],
            years: "Apr 25 Dec 24 Dec 23",
            links: [
          {"label": "Pg 11", "url": "imp_pdf/env_science/1CL501.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Assess conflicts between Anthropocentric and Ecocentric approaches to ethics.",
            badges: [],
            years: "Feb 25 July 24",
            links: [
          {"label": "Pg 14", "url": "imp_pdf/env_science/1CL501.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Environmental Ethics. Climate change as ethical challenge.",
            badges: [],
            years: "Feb 24 Dec 23 Aug 23",
            links: [
          {"label": "Pg 23", "url": "imp_pdf/env_science/1CL501.pdf#page=23"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Introduction to AI & ML",
    code: "1CS101CC25",
    semester: "Semester 1",
    topicCount: 82,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.lightbulb,
    stats: ["📘 6 Modules", "🔢 82 Topics"],
    units: [
      UnitSection(
        title: "Unit I: Foundational Concepts in Artificial Intelligence (5 hrs)",
        questions: [
          QuestionItem(
            title: "With a neat diagram, explain the basic structure of a computer system (Input Unit, CPU, Output Unit, Memory).",
            badges: ["Diagram"],
            years: "Apr 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 376", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=376"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between Primary Memory (RAM/ROM) and Secondary Memory. Explain the role of Cache and Registers.",
            badges: ["Theory"],
            years: "Dec 23",
            links: [
          {"label": "📘 Course Pg 386", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=386"},
          {"label": "📝 Exam Pg 10", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe the functions of Control Unit (CU) and Arithmetic Logic Unit (ALU) within the CPU.",
            badges: ["Theory"],
            years: "Dec 23",
            links: [
          {"label": "📘 Course Pg 381", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=381"},
          {"label": "📝 Exam Pg 10", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the problem formulation steps: Define problem, scope, objectives, data requirements, evaluation methods, constraints.",
            badges: ["Theory"],
            years: "Apr 25 Feb 24",
            links: [
          {"label": "📘 Course Pg 390", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=390"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Outline the general problem-solving process: Analyzing, Algorithm development, Coding, Testing & Debugging, Maintenance.",
            badges: ["High Yield"],
            years: "Feb 25 June 23",
            links: [
          {"label": "📘 Course Pg 392", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=392"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Artificial Intelligence. Compare and contrast Human Intelligence and Artificial Intelligence across dimensions: Adapting, Digital vs Analogue, Thinking & Reasoning.",
            badges: ["High Yield", "Diagram"],
            years: "Apr 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 338", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=338"},
          {"label": "📝 Exam Pg 17", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Trace the history of AI across four phases: Foundations (1941–1950), Birth & Early Excitement (1956–1970s), Expert Systems (1980–2000), Modern AI (2000–Present).",
            badges: ["Theory"],
            years: "Feb 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 341", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=341"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the Turing Test (1950) and its significance in AI. Describe ELIZA (1966), Deep Blue (1997), and IBM Watson (2011).",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 344", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=344"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Distinguish between Data, Information, and Knowledge with real-world examples. Explain the transformation pipeline.",
            badges: ["High Yield"],
            years: "Feb 25 June 23",
            links: [
          {"label": "📘 Course Pg 355", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=355"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Rule-based Knowledge Representation (IF-THEN rules) with examples like MYCIN.",
            badges: ["Theory"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 361", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=361"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Structural Knowledge Representation and explain why it is more powerful than rule-based systems for reasoning.",
            badges: ["Theory"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 362", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=362"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define and exemplify AI jargons: Algorithm, Machine Learning, Neural Network, Training Data, Natural Language Processing, Prediction.",
            badges: ["High Yield"],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 358", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=358"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss the importance and applications of AI in different domains: Healthcare, Finance, Autonomous Vehicles, Education, Entertainment.",
            badges: ["Theory"],
            years: "Feb 25 June 23",
            links: [
          {"label": "📘 Course Pg 363", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=363"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain any five Computer Vision applications (Face Recognition, Autonomous Vehicles, Object Detection, Semantic Segmentation, Emotion Recognition).",
            badges: ["Diagram"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 363", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=363"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe any five Natural Language Processing applications (Machine Translation, Sentiment Analysis, Chatbots, NER, Speech Recognition).",
            badges: ["Theory"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 369", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=369"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "Unit II: Data Exploration (6 hrs)",
        questions: [
          QuestionItem(
            title: "Classify and explain Structured, Semi-structured, and Unstructured Data with examples (SQL tables, JSON, images/video).",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24",
            links: [
          {"label": "📘 Course Pg 398", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=398"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain any six data collection methods: Interviews, Questionnaires & Surveys, Observations, Documents & Records, Focus Groups, Oral Histories, Sensors, Kaggle, WHO/World Bank portals, Open Government Portals.",
            badges: ["Theory"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 409", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=409"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What are the different types of data issues that can arise during collection? Explain Erroneous Data, Invalid/Null values, Missing Data, and Outliers.",
            badges: ["Theory"],
            years: "Feb 25 Feb 24",
            links: [
          {"label": "📘 Course Pg 435", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=435"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss six methods for handling missing values: Ignore the tuple, Delete column, Fill manually, Global constant, Attribute mean/mode, Class-specific mean/mode.",
            badges: ["Top Repeat"],
            years: "Apr 25 Feb 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 419", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=419"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical: On the Titanic dataset, identify missing values in Age and Cabin. Fill Age using mean of survived class, Cabin using mode of survived class.",
            badges: ["Numerical"],
            years: "Feb 25",
            links: [
          {"label": "📘 Course Pg 430", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=430"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the impact of improperly handled missing data on machine learning model performance.",
            badges: ["Theory"],
            years: "Apr 25 June 23",
            links: [
          {"label": "📘 Course Pg 421", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=421"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is a Box Plot? Explain the five-number summary (Min, Q1, Median, Q3, Max) and how to identify outliers using IQR.",
            badges: ["High Yield", "Diagram", "Numerical"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 449", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=449"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical: Calculate Q1, Q3, IQR and identify outliers for dataset: 52, 55, 71, 75, 81, 83, 85, 89, 90, 90, 99, 100, 100.",
            badges: ["Numerical"],
            years: "Feb 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 453", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=453"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Scatter Plots and Bubble Charts. How can a bubble chart visualize 4 features simultaneously?",
            badges: ["Diagram"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 440", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=440"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between Bar Chart and Histogram. When should each be used?",
            badges: ["Theory"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 474", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=474"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is a Line Chart? Explain its use in visualizing trends over time with an example.",
            badges: ["Diagram"],
            years: "June 23",
            links: [
          {"label": "📘 Course Pg 478", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=478"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Exploratory Data Analysis (EDA) using the Titanic dataset as an example. What insights can be drawn?",
            badges: ["Theory"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 481", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=481"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "Unit III: Introduction to State Space & State Space Search (5 hrs)",
        questions: [
          QuestionItem(
            title: "Define State, State Space, and State Space Search with examples: 8-Puzzle, Tic-Tac-Toe, Vacuum Cleaner Problem.",
            badges: ["Top Repeat", "Diagram"],
            years: "Apr 25 Feb 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 486", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=486"},
          {"label": "📝 Exam Pg 10", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Formally represent a search problem as P = {S, A, Action(S), Result(S,a), Cost(S,a)} with the 8-puzzle as an example.",
            badges: ["Theory"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 499", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=499"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Problem Reduction with AND-OR graphs. Give an example (Build a House, Unlock Door, Matrix Multiplication).",
            badges: ["Diagram"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 522", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=522"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write the Simple Hill Climbing algorithm. Solve 8-puzzle using heuristic h(n) = number of tiles in correct place.",
            badges: ["High Yield", "Algorithm", "Numerical"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 569", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=569"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write the Steepest-Ascent Hill Climbing algorithm. Solve 8-puzzle using Manhattan distance heuristic. Show all steps.",
            badges: ["High Yield", "Algorithm", "Numerical"],
            years: "Feb 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 582", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=582"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the Generate-and-Test algorithm with an example (password cracking). Compare with Hill Climbing.",
            badges: ["Algorithm"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 535", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=535"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe the limitations of Hill Climbing: Local Maxima, Plateaus, and Ridges. What solutions exist (Random Restart, Simulated Annealing)?",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 589", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=589"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "8-Puzzle Heuristic Calculation: For a given initial state, compute h-values using (a) Manhattan distance, (b) Number of misplaced tiles, (c) Number of tiles in correct place.",
            badges: ["High Yield", "Numerical"],
            years: "Apr 25 Feb 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 578", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=578"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "TSP – Brute Force: For a 4-city/6-city TSP, find the best tour and tour length by generating all permutations.",
            badges: ["High Yield", "Numerical"],
            years: "Feb 25 Mar 24 June 23",
            links: [
          {"label": "📘 Course Pg 543", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=543"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "TSP – Nearest Neighbour Heuristic: Apply NNH on a 6-city symmetric TSP. Compare result with brute-force optimal.",
            badges: ["Numerical"],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 555", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=555"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compare BFS and DFS for state space search. Write algorithms for both and discuss advantages/disadvantages.",
            badges: ["Algorithm"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 508", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=508"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "Unit IV: Introduction to Machine Learning (10 hrs)",
        questions: [
          QuestionItem(
            title: "Define Machine Learning. Explain the ML Life Cycle with a diagram: Gathering Data → Preparation → Wrangling → Analysis → Train → Test → Deployment.",
            badges: ["Diagram"],
            years: "Apr 25 Feb 24",
            links: [
          {"label": "📘 Course Pg 603", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=603"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between AI, ML, and DL. Explain how ML is a subset of AI and DL is a subset of ML.",
            badges: ["High Yield", "Diagram"],
            years: "Apr 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 328", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=328"},
          {"label": "📝 Exam Pg 17", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe the role of Machine Learning in different domains: Healthcare, Finance, Retail, Autonomous Vehicles, Entertainment.",
            badges: ["Theory"],
            years: "Feb 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 602", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=602"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Overfitting and Underfitting with regression examples. What are the causes and solutions for each?",
            badges: ["High Yield", "Diagram"],
            years: "Feb 25 Mar 24 June 23",
            links: [
          {"label": "📘 Course Pg 612", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=612"},
          {"label": "📝 Exam Pg 17", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between Supervised, Unsupervised, Semi-Supervised, and Reinforcement Learning with suitable examples.",
            badges: ["Top Repeat"],
            years: "Apr 25 Feb 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 621", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=621"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Distinguish between Classification and Regression problems. List three algorithms for each with real-world examples.",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 624", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=624"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write the KNN Classification algorithm. How to choose the value of k? What is the significance of odd k?",
            badges: ["High Yield", "Algorithm"],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 634", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=634"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – KNN Classification: Classify a new patient (BP=135, Cholesterol=215) as Healthy/Diseased using distance-weighted 3-NN (Euclidean distance).",
            badges: ["Top Repeat", "Numerical"],
            years: "Apr 25 Feb 25 June 23",
            links: [
          {"label": "📘 Course Pg 653", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=653"},
          {"label": "📝 Exam Pg 18", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – KNN Classification: Predict species of an egg (weight=11g, volume=9cm³) using simple 3-NN and distance-weighted 3-NN.",
            badges: ["Numerical"],
            years: "Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 639", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=639"},
          {"label": "📝 Exam Pg 15", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – KNN Regression: Predict house price (size=1600 sq m) using KNN regression with K=3 after Min-Max normalization.",
            badges: ["High Yield", "Numerical"],
            years: "Feb 25 June 23",
            links: [
          {"label": "📘 Course Pg 669", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=669"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – Weighted KNN Regression: Predict fish caught by 15 fishermen in 2 hrs using uniform-weighted 3-NN after normalization.",
            badges: ["Numerical"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 680", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=680"},
          {"label": "📝 Exam Pg 23", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=23"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain performance metrics for classification: Confusion Matrix, Accuracy, Precision, Recall, F1-Score.",
            badges: ["Theory"],
            years: "June 23",
            links: [
          {"label": "📘 Course Pg 662", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=662"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain loss functions for regression: MAE, MSE, RMSE, MAPE with formulas and interpretation.",
            badges: ["Theory"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 686", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=686"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write the K-Means Clustering algorithm. Discuss its applications in customer segmentation, image compression, anomaly detection.",
            badges: ["High Yield", "Algorithm"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 692", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=692"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – K-Means: Cluster 8 points A1(2,10)...A8(4,9) into 3 clusters with initial centroids A1, B1, C1. Show 2 iterations with centroid updates.",
            badges: ["Top Repeat", "Numerical"],
            years: "Apr 25 Feb 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 693", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=693"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – K-Means: Cluster 7 points (1,1)...(7,12) into K=2 clusters. Show cluster membership and centroids after 2 iterations.",
            badges: ["Numerical"],
            years: "Feb 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 707", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=707"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the analogy from Biological Neuron to Artificial Neuron. Draw a labeled diagram of a perceptron.",
            badges: ["Diagram"],
            years: "Feb 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 323", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=323"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Hebbian Learning (\"Neurons that fire together, wire together\") with an example.",
            badges: ["Theory"],
            years: "June 23",
            links: [
          {"label": "📘 Course Pg 343", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=343"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the Perceptron Learning Rule. Train a perceptron for AND gate. Show computation for one epoch (initial weights=1, bias=1, η=0.2).",
            badges: ["Top Repeat", "Numerical"],
            years: "Apr 25 Mar 24 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 324", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=324"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – 1D Perceptron: Train perceptron on 1D patterns (0.0, 0.18, 0.43 → class 0; 0.61, 0.77, 0.93, 1.0 → class 1) with η=0.12 for two epochs.",
            badges: ["Numerical"],
            years: "Mar 24 Feb 24",
            links: [
          {"label": "📘 Course Pg 324", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=324"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – 2D Perceptron: Train perceptron on 7 points (x1={1..7}, x2={1,3,5,3,2,6,1}) with labels {1,0,1,0,0,1,1} for one epoch.",
            badges: ["Numerical"],
            years: "Apr 25 June 23",
            links: [
          {"label": "📘 Course Pg 324", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=324"},
          {"label": "📝 Exam Pg 18", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Why can't a single perceptron solve XOR? Show how a multi-layer network can solve XOR using 2 hidden neurons.",
            badges: ["Rare", "Diagram"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 326", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=326"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Reinforcement Learning. Explain the Q-Learning algorithm with a 5-room building example (states 0-5, goal=room 5).",
            badges: ["Top Repeat", "Numerical"],
            years: "Apr 25 Feb 25 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 713", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=713"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write the Q-value update equation: Q(s,a) = R(s,a) + γ · max Q(s', a'). Explain the role of R-matrix, Q-matrix, and γ (gamma).",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 715", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=715"},
          {"label": "📝 Exam Pg 17", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Numerical – Q-Learning: Trace two episodes of Q-learning (γ=0.8) starting from state 1, then state 3. Show updated Q-matrix after each episode.",
            badges: ["Numerical"],
            years: "Feb 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 716", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=716"},
          {"label": "📝 Exam Pg 10", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=10"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Grid-based RL: 3×3 grid with Start, Goal (+5), Danger (−10). Agent actions: Left, Right, Up, Down.",
            badges: ["Rare"],
            years: "Dec 23",
            links: [
          {"label": "📘 Course Pg 713", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=713"},
          {"label": "📝 Exam Pg 11", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "Unit V: Introduction to Deep Learning (4 hrs)",
        questions: [
          QuestionItem(
            title: "Explain the role of Deep Learning in AI. Differentiate Machine Learning vs Deep Learning with a comparison table.",
            badges: ["High Yield"],
            years: "Apr 25 Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 719", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=719"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "List and describe the four major architectures of Deep Networks: UPNs (Autoencoders, DBNs, GANs), CNNs, RNNs, Recursive Neural Networks. State 2 example networks and use cases for each.",
            badges: ["Top Repeat"],
            years: "Feb 25 Mar 24 Dec 23 June 23",
            links: [
          {"label": "📘 Course Pg 723", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=723"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Convolutional Neural Networks (CNNs) with a diagram showing convolution, pooling, and fully connected layers. List use cases.",
            badges: ["Diagram"],
            years: "Apr 25 June 23",
            links: [
          {"label": "📘 Course Pg 732", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=732"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Recurrent Neural Networks (RNNs) and their use in sequence data. Differentiate RNNs from Recursive Neural Networks.",
            badges: ["Theory"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 737", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=737"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Autoencoders (Encoder-Decoder) and Generative Adversarial Networks (GANs) with applications.",
            badges: ["Theory"],
            years: "Dec 23",
            links: [
          {"label": "📘 Course Pg 724", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=724"},
          {"label": "📝 Exam Pg 11", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=11"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss Symmetric and Asymmetric Neural Network architectures with proper diagrams.",
            badges: ["Rare", "Diagram"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 723", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=723"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "6. Python Programming & Practical Implementation for ML",
        questions: [
          QuestionItem(
            title: "Write a Python program using Pandas to read a CSV file, display first/last 5 rows using head()/tail(), and get data summary using describe().",
            badges: ["Python"],
            years: "Apr 25",
            links: [
          {"label": "📘 Course Pg 170", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=170"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a Python program to handle missing values in four different ways: dropna(), fillna with mean, fillna with mode, fillna with constant.",
            badges: ["Python"],
            years: "Feb 24 June 23",
            links: [
          {"label": "📘 Course Pg 170", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=170"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Create a Pandas DataFrame from a dictionary. Perform operations: loc[], iloc[], add/rename/delete columns, Boolean indexing.",
            badges: ["Python"],
            years: "Feb 25",
            links: [
          {"label": "📘 Course Pg 191", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=191"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write Python code using Matplotlib to plot: (a) Line chart with markers, (b) Scatter plot with color-coded classes, (c) Histogram with bins, (d) Bar chart.",
            badges: ["Python", "Diagram"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 229", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=229"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Implement NumPy operations: transpose(), flatten(), concatenate() with axis=0 and axis=1, broadcasting, zeros(), ones(), arange() with reshape().",
            badges: ["Python"],
            years: "Feb 24",
            links: [
          {"label": "📘 Course Pg 121", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=121"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a program to read Iris/Boston data, split into train/test sets based on user input (without sklearn), and print shapes.",
            badges: ["Python"],
            years: "Apr 25 Mar 24",
            links: [
          {"label": "📘 Course Pg 306", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=306"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Implement KNN Classification on Iris dataset using sklearn. Use distance-weighted KNN (K=user input) and print accuracy, classification report.",
            badges: ["Python"],
            years: "Apr 25",
            links: [
          {"label": "📘 Course Pg 310", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=310"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Implement Weighted KNN Regression from scratch (without sklearn) to predict Boston house prices. Calculate MAE, MSE, RMSE, MAPE.",
            badges: ["Python"],
            years: "Feb 25",
            links: [
          {"label": "📘 Course Pg 316", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=316"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Implement K-Means Clustering on Iris dataset. Print centroids and cluster assignments for test data. Show both sklearn and user-defined versions.",
            badges: ["Python"],
            years: "Feb 25",
            links: [
          {"label": "📘 Course Pg 319", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=319"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Code a Perceptron from scratch for AND gate with weight update loop. Plot the decision boundary using matplotlib.",
            badges: ["Python"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 324", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=324"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Implement TSP Brute-Force and Nearest Neighbour Heuristic for 6 cities. Print best tour, tour length, and execution time.",
            badges: ["Python"],
            years: "Apr 25",
            links: [
          {"label": "📘 Course Pg 299", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=299"},
          {"label": "📝 Exam Pg 16", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a program to calculate descriptive statistics (mean, variance, standard deviation, median, mode, range) manually without libraries.",
            badges: ["Python"],
            years: "Mar 24",
            links: [
          {"label": "📘 Course Pg 287", "url": "/imp_pdf/ai_ml/1CS101 full course.pdf#page=287"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/ai_ml/1CS101 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Web Programming",
    code: "1CS201CC25",
    semester: "Semester 1",
    topicCount: 30,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.device_desktop,
    stats: ["📘 5 Modules", "🔢 30 Topics"],
    units: [
      UnitSection(
        title: "📄 UNIT I: HTML & CSS – STRUCTURE, STYLING, LAYOUT",
        questions: [
          QuestionItem(
            title: "Write HTML code to generate a complex table with rowspan and colspan (e.g., College Departments & Courses). [06]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Apr 25 Dec 24 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 63", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=63"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "How <frameset> and <frame> divide a web page? Write code to split horizontally into three frames (20%,30%,50%) and further split the middle frame vertically. [06]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Dec 24 Apr 25 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 69", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=69"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss the following HTML tags with examples: <hr>, <area>, <select>, <optgroup>, <del>, <map>, <caption>, <th>. [06]",
            badges: ["📖 Theory"],
            years: "Dec 24 Apr 25 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 41", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=41"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is the CSS Box Model? Explain the four parts with a labeled diagram. [06]",
            badges: ["🔥 High Yield", "📊 Diagram"],
            years: "Dec 24 Apr 25 Jun 23 May 24 Feb 25",
            links: [
          {"label": "📘 Course Pg 171", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=171"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Inline vs Internal vs External CSS – explain with scenarios of usage in web development. [06]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 24 Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 117", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=117"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Class selector vs ID selector in CSS with suitable examples. [04]",
            badges: ["📖 Theory"],
            years: "Dec 24 Apr 25 Jun 23",
            links: [
          {"label": "📘 Course Pg 115", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=115"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Develop HTML/CSS to create a <div> with four different border styles (solid, dotted, dashed, double) for top, right, bottom, left respectively; also set border‑radius (50% horizontal, 30px vertical) for top‑right and bottom‑left corners. [06]",
            badges: ["💻 Code"],
            years: "Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 143", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=143"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "⚡ UNIT II: JAVASCRIPT – CORE, DOM, EVENTS, VALIDATION",
        questions: [
          QuestionItem(
            title: "Differentiate slice() and splice() methods in JavaScript with suitable examples. [04]",
            badges: ["🔥 High Yield", "📖 Compare"],
            years: "Apr 25 Dec 24 Jun 23 May 24 Feb 25",
            links: [
          {"label": "📘 Course Pg 254", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=254"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate substr() and substring() methods with examples. [04]",
            badges: ["🔥 High Yield", "📖 Compare"],
            years: "Apr 25 Dec 24 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 261", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=261"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss the use of eval(), parseInt(), isNaN() with suitable examples. [06]",
            badges: ["💻 Code"],
            years: "Dec 24 Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 265", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=265"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate toString() and valueOf() functions in JavaScript with a required code snippet. [04]",
            badges: ["📖 Compare"],
            years: "Apr 25 May 24 Dec 24",
            links: [
          {"label": "📘 Course Pg 265", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=265"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss any four methods of window object in JavaScript with examples (alert, confirm, prompt, open, close, etc.). [06]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 283", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=283"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a JavaScript function FindLargest(arr) that returns the largest number from an array (or null if empty). [06]",
            badges: ["💻 Code"],
            years: "Feb 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 243", "url": "1CS201 full course pdf#page=243"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a JavaScript program that prints numbers 1 to 100: multiples of 3 → \"Fizz\", 5 → \"Buzz\", both → \"FizzBuzz\". [06]",
            badges: ["💻 Code"],
            years: "Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 250", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=250"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Design a registration form with HTML + JavaScript validation: Full Name (alphabets & spaces), Email (valid format), Password (min 8 chars, 1 uppercase, 1 digit, 1 special), Confirm Password, Phone (10 digits), DOB (≥18 years), Terms checkbox. [06]",
            badges: ["🔥 High Yield", "💻 Full Stack"],
            years: "Apr 25 May 24 Dec 24",
            links: [
          {"label": "📘 Course Pg 291", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=291"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write JavaScript to calculate days left until next birthday from user‑entered date of birth. [06]",
            badges: ["💻 Code"],
            years: "Dec 24 Apr 25 Jun 23",
            links: [
          {"label": "📘 Course Pg 309", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=309"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🧩 UNIT III: JQUERY & ANGULARJS – DYNAMIC WEB APPS",
        questions: [
          QuestionItem(
            title: "Explain any four jQuery events (click, dblclick, mouseenter, hover, focus, blur) with code snippets. [08]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Apr 25 May 24 Dec 24",
            links: [
          {"label": "📘 Course Pg 327", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=327"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Design a web page containing an image and a button \"Toggle Image\". When clicked, the image hides/shows with a smooth transition using jQuery. [06]",
            badges: ["💻 Code"],
            years: "Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 332", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=332"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "How do you slide elements using jQuery? Give an example of slideToggle() method. [04]",
            badges: ["💻 Code"],
            years: "Dec 24 Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 334", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=334"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What are AngularJS directives? Explain ng‑show, ng‑repeat, and ng‑click with suitable examples. [08]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 348", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=348"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "How does data binding work in AngularJS? Demonstrate two‑way data binding with an example (input field bound to a model, display the entered text in real‑time). [06]",
            badges: ["💻 Code"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 360", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=360"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Create an AngularJS application that allows the user to input two numbers and dynamically display their sum, difference, and product using two‑way data binding. [06]",
            badges: ["💻 Code"],
            years: "Apr 25 May 24",
            links: [
          {"label": "📘 Course Pg 351", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=351"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🖥️ UNIT IV: BACKEND (PHP) & WEB DEPLOYMENT",
        questions: [
          QuestionItem(
            title: "Describe the use of functions in PHP, including how to define and call functions. Explain argument passing by reference and default argument values, and how to return values. [06]",
            badges: ["🔥 High Yield", "💻 Code"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 421", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=421"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss the various web hosting methods used for deploying websites (shared, VPS, dedicated, cloud) along with their pros and cons. [06]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 375", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=375"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss the process of web development from requirement analysis to deployment. Illustrate the overall workflow using an appropriate flowchart. [06]",
            badges: ["📊 Diagram"],
            years: "Apr 25 Dec 24 May 24",
            links: [
          {"label": "📘 Course Pg 14", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=14"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define the client‑server architecture and discuss its role & working in web development with a suitable diagram. [06]",
            badges: ["📊 Diagram"],
            years: "Dec 24 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 5", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=5"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📘 BONUS: ADDITIONAL HIGH‑YIELD PRACTICAL QUESTIONS",
        questions: [
          QuestionItem(
            title: "Write CSS rules to: (i) set hyperlinks blue without underline, on mouse hover change background to green; (ii) set \"college.gif\" as background image repeating only vertically; (iii) change text color of all <p> inside a <div> to red; (iv) set list‑item marker of unordered list to an image. [06]",
            badges: ["💻 Code"],
            years: "May 24 Dec 24",
            links: [
          {"label": "📘 Course Pg 131", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=131"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a JavaScript function that takes an array of integers and returns a new array containing only the prime numbers. Display the new array in an alert box. [06]",
            badges: ["💻 Code"],
            years: "May 24 Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 252", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=252"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Create a login screen using HTML and JavaScript: username should not start with '_', '@' or number; password length must be 5 to 16 characters; both fields cannot be blank. [06]",
            badges: ["💻 Code"],
            years: "Feb 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 290", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=290"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write jQuery code to (i) toggle the visibility of a specific element when a button is clicked; (ii) slide‑toggle a <div> element with class \"toggleDiv\" when a button is clicked. [06]",
            badges: ["💻 Code"],
            years: "May 24 Dec 24",
            links: [
          {"label": "📘 Course Pg 332", "url": "/imp_pdf/web_prog/1CS201 full course.pdf#page=332"},
          {"label": "📝 Exam Pg 19", "url": "/imp_pdf/web_prog/1CS201 question bank.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Computer Programming",
    code: "1CS501CC25",
    semester: "Semester 1",
    topicCount: 36,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.settings,
    stats: ["📘 4 Modules", "🔢 36 Topics"],
    units: [
      UnitSection(
        title: "1. Introduction to C & Computer Basics",
        questions: [
          QuestionItem(
            title: "Explain the Basic Structure of a Computer with a neat diagram.",
            badges: ["Diagram"],
            years: "May 24",
            links: [
          {"label": "Pg 15", "url": "imp_pdf/comp_prog/1CS501.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate: System vs Application Software OR IDE vs Application Software.",
            badges: [],
            years: "Feb 25 Feb 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/comp_prog/1CS501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Compiler, Interpreter, Assembler? Name C compilers.",
            badges: ["High Yield"],
            years: "Apr 25",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between High-level language and Low-level language.",
            badges: [],
            years: "Mar 24",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/comp_prog/1CS501.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Tokens. Give examples (Operators, Keywords, Identifiers).",
            badges: [],
            years: "Apr 25",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/comp_prog/1CS501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss Salient Features or Applications of C Language.",
            badges: [],
            years: "Feb 25 Feb 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/comp_prog/1CS501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Rules for constructing Identifiers/Variables. Classify valid/invalid: abc2, \$abc1, +abc, 100_abc, #num.",
            badges: ["High Yield"],
            years: "May 24 June 23",
            links: [
          {"label": "Pg 13", "url": "imp_pdf/comp_prog/1CS501.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Data Types: int, long, float (Size, Range, Memory).",
            badges: [],
            years: "Feb 25 Mar 24 Feb 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/comp_prog/1CS501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss Escape Sequence characters.",
            badges: [],
            years: "Mar 24",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/comp_prog/1CS501.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "2. Logic, Flowcharts & Operators",
        questions: [
          QuestionItem(
            title: "Explain Type Conversion (Implicit vs Explicit) with code.",
            badges: ["High Yield"],
            years: "Apr 25 May 24 Mar 24 Feb 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/comp_prog/1CS501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Operators: Ternary, Bitwise (AND/OR), Shift (Left/Right).",
            badges: ["Code"],
            years: "Feb 25 May 24 Mar 24 Feb 24",
            links: [
          {"label": "Pg 8", "url": "imp_pdf/comp_prog/1CS501.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Precedence and Associativity with a program.",
            badges: ["Rare"],
            years: "Feb 25",
            links: [
          {"label": "Pg 8", "url": "imp_pdf/comp_prog/1CS501.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate expressions (e.g., a+=b*=c-=5 or Logical/Relational mix).",
            badges: [],
            years: "May 24",
            links: [
          {"label": "Pg 15", "url": "imp_pdf/comp_prog/1CS501.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is an Algorithm/Flowchart? Draw/Write for: Largest of 3, Prime, Armstrong, Average of N, Arithmetic Ops.",
            badges: ["Diagram"],
            years: "Apr 25 Mar 24 June 23 Feb 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/comp_prog/1CS501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write algorithm to Swap two numbers (with and without temp variable).",
            badges: [],
            years: "Feb 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/comp_prog/1CS501.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Switch Case: Area of Geometrical figures OR Odd/Even checker.",
            badges: [],
            years: "Apr 25 June 23",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/comp_prog/1CS501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Loops/Math: Gross Salary Calc, Electricity Bill Calc, Product of digits.",
            badges: ["Program"],
            years: "Apr 25 May 24 June 23",
            links: [
          {"label": "Pg 13", "url": "imp_pdf/comp_prog/1CS501.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Break, Continue, Goto, Nested If, While Loop with examples.",
            badges: [],
            years: "Feb 25 Apr 25 Mar 24 Feb 24 June 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Pattern Printing: Pyramid of numbers/alphabets.",
            badges: ["Code"],
            years: "Mar 24 Feb 24",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/comp_prog/1CS501.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "3. Arrays & Strings",
        questions: [
          QuestionItem(
            title: "1D Array Ops: Sum of elements, Average, Frequency of number, Reverse array, Remove duplicates.",
            badges: ["High Yield"],
            years: "Apr 25 May 24 Mar 24 Feb 24 June 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Matrix (2D): Transpose, Symmetric check, Multiplication, Identity Matrix conversion, Sum of Diagonals.",
            badges: ["Program"],
            years: "Feb 25 Apr 25 Mar 24 Feb 24",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Real Life Array: Student Marks (2D Array) - Total/Average marks.",
            badges: [],
            years: "Feb 25",
            links: [
          {"label": "Pg 8", "url": "imp_pdf/comp_prog/1CS501.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "String Logic: Count Vowels/Consonants, Reverse sentence, Concatenate without library, Copy without library.",
            badges: ["High Yield"],
            years: "Apr 25 Feb 25 May 24 June 23",
            links: [
          {"label": "Pg 7", "url": "imp_pdf/comp_prog/1CS501.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Library Functions: strlen vs sizeof, strcpy, strncpy, strcmp.",
            badges: [],
            years: "Feb 25 Mar 24 Feb 24",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/comp_prog/1CS501.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "4. Functions, Pointers & Structures",
        questions: [
          QuestionItem(
            title: "User Defined Function: Definition, Elements, Classification with examples.",
            badges: [],
            years: "May 24",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/comp_prog/1CS501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate: Call by Value vs Call by Reference (Swap program).",
            badges: ["Top Repeat"],
            years: "Apr 25 Feb 25 May 24",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Recursion: Definition. Program for Factorial.",
            badges: [],
            years: "Apr 25 May 24",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Programs via Function: Power(x,y), Square, Binary to Decimal, IsPrime(num).",
            badges: [],
            years: "May 24 Mar 24 June 23 Feb 24",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/comp_prog/1CS501.pdf#page=16"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate: Actual Arguments vs Formal Arguments.",
            badges: [],
            years: "Mar 24",
            links: [
          {"label": "Pg 4", "url": "imp_pdf/comp_prog/1CS501.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Pointers: Definition, Adv/Disadv, Void Pointer. Program: Sum/Mean of array, Reverse array, String length.",
            badges: ["High Yield"],
            years: "Apr 25 May 24 Mar 24 June 23 Feb 24",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Give output of code snippet involving pointer arithmetic.",
            badges: ["Rare"],
            years: "Apr 25",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/comp_prog/1CS501.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "File Handling: Functions (getw, putw, fscanf, fprintf, rewind). Why files?",
            badges: [],
            years: "Apr 25 June 23",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/comp_prog/1CS501.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "File Programs: Count vowels, Read/Display content, Separate Prime/Non-prime numbers.",
            badges: [],
            years: "Feb 25 Mar 24 Feb 24",
            links: [
          {"label": "Pg 9", "url": "imp_pdf/comp_prog/1CS501.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Structure Definition, Syntax. Array of Structures vs Array.",
            badges: [],
            years: "Feb 24 June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/comp_prog/1CS501.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Record Management Programs: Employee/Student/Product (ID, Name, Salary/Marks). Logic: Max salary, Date join, Grade calculation.",
            badges: ["Code"],
            years: "Apr 25 Feb 25 May 24 Mar 24 June 23",
            links: [
          {"label": "Pg 7", "url": "imp_pdf/comp_prog/1CS501.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Scope and Lifetime of variables.",
            badges: [],
            years: "Feb 24 June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/comp_prog/1CS501.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Electrical Science",
    code: "1EE801CC25",
    semester: "Semester 1",
    topicCount: 17,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.bolt,
    stats: ["📘 5 Modules", "🔥 25 High-Yield Questions", "🔢 Numerical Solutions", "💎 Rare Topics"],
    units: [
      UnitSection(
        title: "1. DC Circuits & Electrostatics",
        questions: [
          QuestionItem(
            title: "Apply Mesh Analysis to find current/power in a specific resistor. [See Diagram in PDF]",
            badges: ["Top Repeat", "Calc"],
            years: "Dec 24, Apr 25, July 25, July 24, Feb 24, June 23, Aug 23",
            links: [
          {"label": "Pg 16", "url": "imp_pdf/electrical/1EE801.pdf#page=16"},
            ],
            answer: "Method:\n                1. Identify loops (meshes). Assign currents I1, I2, I3.\n                2. Apply KVL to each loop: Σ(Voltage Rises) = Σ(Voltage Drops).\n                3. Solve simultaneous equations for I values.\n                4. Branch current = (I1 - I2) or similar depending on direction.",
            formula: "",
          ),
          QuestionItem(
            title: "Apply Nodal Analysis to find Node Voltages (V1, V2). [See Diagram in PDF]",
            badges: ["Top Repeat", "Calc"],
            years: "Dec 24, Apr 25, July 25, July 24, Feb 24, May 24, Aug 23",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/electrical/1EE801.pdf#page=19"},
            ],
            answer: "Method:\n                1. Identify Nodes. Select one Reference Node (0V).\n                2. Apply KCL at each non-reference node: Σ(Currents leaving) = 0.\n                3. Express currents as (V_node - V_neighbour)/R.\n                4. Solve for V1, V2.",
            formula: "",
          ),
          QuestionItem(
            title: "Star-Delta Transformation. Find Equivalent Resistance. [See Diagram in PDF]",
            badges: ["High Yield"],
            years: "Feb 25, Apr 25, Dec 23, July 24, Mar 24",
            links: [
          {"label": "Pg 22", "url": "imp_pdf/electrical/1EE801.pdf#page=22"},
            ],
            answer: "",
            formula: "Delta to Star:\n                Ra = (R1*R2) / (R1+R2+R3)\nStar to Delta:\n                R12 = Ra + Rb + (Ra*Rb)/Rc",
          ),
          QuestionItem(
            title: "Superposition Theorem. Find current in a resistor.",
            badges: ["High Yield"],
            years: "Apr 25, July 25, Dec 23, Aug 23, May 24",
            links: [
          {"label": "Pg 30", "url": "imp_pdf/electrical/1EE801.pdf#page=30"},
            ],
            answer: "Statement: In a linear bilateral network containing more than one source, the response is the algebraic sum of responses caused by each source acting alone.\nStep: Turn off other sources (Short voltage sources, Open current sources).",
            formula: "",
          ),
          QuestionItem(
            title: "Thevenin's / Norton's Theorem. Find Load Current.",
            badges: ["Calc"],
            years: "July 24, Feb 24, June 23",
            links: [
          {"label": "Pg 23", "url": "imp_pdf/electrical/1EE801.pdf#page=23"},
            ],
            answer: "",
            formula: "I_load = Vth / (Rth + RL) [Thevenin]\n                I_load = (I_N * Rn) / (Rn + RL) [Norton]",
          ),
          QuestionItem(
            title: "RC Series Transient (Charging/Discharging). Derive V/I equations. Calc Time Constant.",
            badges: ["Must Do"],
            years: "Feb 25, Dec 24, Apr 25, July 24, Feb 24, June 23",
            links: [
          {"label": "Pg 30", "url": "imp_pdf/electrical/1EE801.pdf#page=30"},
            ],
            answer: "",
            formula: "Charging Voltage: v(t) = V(1 - e^(-t/RC))\nCharging Current: i(t) = (V/R) * e^(-t/RC)\nTime Constant (τ): R * C",
          ),
        ],
      ),
      UnitSection(
        title: "2. AC Circuits & Magnetics",
        questions: [
          QuestionItem(
            title: "RLC Series Circuit. Find Resonance Freq, Q-Factor, Voltages.",
            badges: ["Calc"],
            years: "Apr 25, Mar 24, May 24",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/electrical/1EE801.pdf#page=2"},
            ],
            answer: "",
            formula: "Resonance Freq (fr) = 1 / (2π√(LC))\n                Quality Factor (Q) = (1/R) * √(L/C)\n                At Resonance: Z = R, I = V/R.",
          ),
          QuestionItem(
            title: "Waveform Analysis. Find RMS, Average, Form Factor.",
            badges: ["Graph"],
            years: "Dec 24, July 24, June 23, Aug 23",
            links: [
          {"label": "Pg 28", "url": "imp_pdf/electrical/1EE801.pdf#page=28"},
            ],
            answer: "RMS: Root of the Mean of the Squares.\nAverage: Mean over half cycle (for symmetric).\nForm Factor: RMS Value / Average Value.",
            formula: "",
          ),
          QuestionItem(
            title: "Magnetic Circuit Concepts. MMF, Reluctance, Flux, Fringing, Leakage. Analogy with Electric.",
            badges: ["Theory"],
            years: "Feb 25, July 24, Mar 24, June 23, Aug 23",
            links: [
          {"label": "Pg 18", "url": "imp_pdf/electrical/1EE801.pdf#page=18"},
            ],
            answer: "MMF (Amp-Turns): Analogous to EMF. Force driving flux.\nReluctance (S): Analogous to Resistance. Opposition to flux. S = l / (μA).\nFringing: Spreading of flux lines at air gaps.",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "3. Polyphase & Electronics",
        questions: [
          QuestionItem(
            title: "Star/Delta Relations. Derive Line vs Phase V/I. Numericals on Load Power.",
            badges: ["Top Repeat"],
            years: "Feb 25, Dec 23, Aug 23, July 24, June 23",
            links: [
          {"label": "Pg 21", "url": "imp_pdf/electrical/1EE801.pdf#page=21"},
            ],
            answer: "",
            formula: "Star: IL = Iph, VL = √3 * Vph\nDelta: VL = Vph, IL = √3 * Iph\nPower: P = √3 * VL * IL * cos(Φ)",
          ),
          QuestionItem(
            title: "2-Wattmeter Method. Find Power & PF.",
            badges: ["Calc"],
            years: "Dec 24, July 24, Aug 23, May 24",
            links: [
          {"label": "Pg 21", "url": "imp_pdf/electrical/1EE801.pdf#page=21"},
            ],
            answer: "",
            formula: "Total Power = W1 + W2\n                PF Angle Φ = tan⁻¹ [ √3 * (W1 - W2) / (W1 + W2) ]",
          ),
          QuestionItem(
            title: "Rectifiers (Half, Full, Bridge). Efficiency & Ripple Factor.",
            badges: ["High Yield"],
            years: "Dec 23, Aug 23, July 24, June 23, May 24",
            links: [
          {"label": "Pg 21", "url": "imp_pdf/electrical/1EE801.pdf#page=21"},
            ],
            answer: "Efficiency (max): HWR = 40.6%, FWR = 81.2%.\nRipple Factor: HWR = 1.21, FWR = 0.48.",
            formula: "",
          ),
          QuestionItem(
            title: "BJT Transistor. Construction, Amplifier/Switch modes.",
            badges: ["Diagram"],
            years: "Dec 24, July 24, Dec 23, Aug 23, May 24",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/electrical/1EE801.pdf#page=12"},
            ],
            answer: "Active Mode: E-B fwd bias, C-B rev bias -> Acts as Amplifier.\nSaturation Mode: Both fwd bias -> Acts as Closed Switch (ON).\nCutoff Mode: Both rev bias -> Acts as Open Switch (OFF).",
            formula: "",
          ),
          QuestionItem(
            title: "Special Diodes (Zener, LED, Photo).",
            badges: ["Rare"],
            years: "Dec 23, Aug 23, July 24",
            links: [
          {"label": "Pg 12", "url": "imp_pdf/electrical/1EE801.pdf#page=12"},
            ],
            answer: "Zener: Voltage Regulator (Rev Bias).\nLED: Light Emitter (Fwd Bias).\nPhotodiode: Light Detector (Rev Bias).",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "4. Digital Electronics",
        questions: [
          QuestionItem(
            title: "Logic Circuit Analysis. Write Output Expression & Truth Table. [See Diagram in PDF]",
            badges: ["Must Do"],
            years: "Dec 23, Aug 23, June 23, May 24, Dec 24",
            links: [
          {"label": "Pg 21", "url": "imp_pdf/electrical/1EE801.pdf#page=21"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Number Conversion. (Hex/Octal/Binary/Decimal).",
            badges: ["Math"],
            years: "All Years",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/electrical/1EE801.pdf#page=3"},
            ],
            answer: "Tip: Use binary as a bridge. (e.g., Hex -> Binary -> Octal).\n                Hex to Bin: 1 hex digit = 4 bits.\n                Octal to Bin: 1 octal digit = 3 bits.",
            formula: "",
          ),
          QuestionItem(
            title: "Full Adder using Half Adders / XOR using NAND.",
            badges: ["Design"],
            years: "Aug 23, Dec 23, July 24",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/electrical/1EE801.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "General English",
    code: "1HS101CC25",
    semester: "Semester 1",
    topicCount: 0,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.chat_bubble,
    stats: ["📘 4 Modules", "🔢 0 Topics"],
    units: [
      UnitSection(
        title: "1. Literature: Stories & Poems",
        questions: [
        ],
      ),
      UnitSection(
        title: "2. Linguistics & Phonetics",
        questions: [
        ],
      ),
      UnitSection(
        title: "3. Communication Skills (LSRW)",
        questions: [
        ],
      ),
      UnitSection(
        title: "4. Grammar, Vocab & Application",
        questions: [
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Written Communication",
    code: "1HS102CC25",
    semester: "Semester 1",
    topicCount: 27,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.doc,
    stats: ["📘 5 Modules", "🔢 27 Topics"],
    units: [
      UnitSection(
        title: "📚 UNIT I: FUNDAMENTALS OF WRITTEN COMMUNICATION",
        questions: [
          QuestionItem(
            title: "Explain Clarity, Conciseness, and Courtesy in detail with reference to the seven Cs of writing. [10]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 54", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=54"},
          {"label": "📝 Exam Pg 19", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the essentials of effective communication along with the 7Cs and other principles of technical communication. [10]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 25 Apr 25 Jun 24",
            links: [
          {"label": "📘 Course Pg 54", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=54"},
          {"label": "📝 Exam Pg 21", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=21"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Categorize the types of audience. Discuss the problems caused by not understanding your target audience. [10]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 67", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=67"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Regarding the cases: Blog Content Creation, User Experience Design, Training Programs, Public Speaking – analyse your audience as a critical part of effective communication. [10]",
            badges: ["📋 Detailed", "📊 Case-based"],
            years: "Dec 25 Apr 25 Jun 24",
            links: [
          {"label": "📘 Course Pg 68", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=68"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Writing is a messy process, but there are strategies to make it manageable. Examine the stages of writing in the communication process. [10]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 9", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=9"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Appraise the different steps of Revision with reference to Re‑writing (Add, Delete, Reformat, Enhance tone, Correct errors). [10]",
            badges: ["📖 Theory"],
            years: "Apr 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 50", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=50"},
          {"label": "📝 Exam Pg 19", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🎨 UNIT II: DOCUMENT DESIGN & ETHICS",
        questions: [
          QuestionItem(
            title: "Assess the significance of effective document design in enhancing communication clarity. Analyze strategies for integrating visual hierarchy (chunking, headings, white space, typography). [10]",
            badges: ["🔥 High Yield", "📊 Design"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 101", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=101"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is Document Design? How do you implement the strategies of Organization, Order, Access, and Variety? [10]",
            badges: ["📋 Long"],
            years: "Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 105", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=105"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Enumerate different types of Plagiarism (direct, paraphrasing, self, patchwork, source-based, accidental) and the ways to avoid it. [10]",
            badges: ["🔥 High Yield", "📖 Ethics"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 123", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=123"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Most plagiarism is unintentional. Explain the ways to avoid plagiarism (quoting, paraphrasing, summarising, citing sources). [10]",
            badges: ["📖 Theory"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 139", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=139"},
          {"label": "📝 Exam Pg 23", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=23"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "⚖️ UNIT III: PERSUASION & ARGUMENT",
        questions: [
          QuestionItem(
            title: "Describe the idea of the rhetoric triangle when creating persuasive arguments. Include examples relevant to engineering students. [10]",
            badges: ["🔥 High Yield", "📊 Framework"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 2", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=2"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "\"Technical communication calls for making and supporting persuasive claims.\" Discuss the traditional methods of Argument and Persuasion (Arouse, Refute, Give proof, Urge action). [10]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 2", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=2"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write an argumentative essay: \"Technical knowledge alone is not enough to succeed as an engineer; communication skills are equally important.\" (5‑paragraph structure: intro, 2 arguments, counter‑argument + refutation, conclusion). [15]",
            badges: ["📋 Long", "📊 Essay"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 160", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=160"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write an essay arguing that social media has a negative impact on mental health (500 words). [10]",
            badges: ["🔹 Rare", "📖 Essay"],
            years: "Dec 25",
            links: [
          {"label": "📘 Course Pg 160", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=160"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "✉️ UNIT IV: PRACTICAL WRITING – LETTERS, EMAILS, REPORTS, PRÉCIS",
        questions: [
          QuestionItem(
            title: "Write a cover letter for the post of an intern in Elexi company, Indore. Include your educational details, skills, and enclosure. [10]",
            badges: ["🔥 High Yield", "📊 Format"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 152", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=152"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write an email to the coordinator of sports and cultural events asking for permission and equipment for organizing a Vaudeville event. [10]",
            badges: ["🔥 High Yield", "📊 Email"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 154", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=154"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "You missed the internal assessment deadline due to a technical issue with the college portal. Write a formal apology email to your course instructor. [15]",
            badges: ["📋 Long"],
            years: "Dec 25 Apr 25",
            links: [
          {"label": "📘 Course Pg 154", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=154"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Draft an email requesting feedback from your colleague or supervisor regarding a project or presentation. [10]",
            badges: ["📊 Email"],
            years: "Dec 25 Apr 25",
            links: [
          {"label": "📘 Course Pg 156", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=156"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a trip report on a conference you attended in Pune/Bengaluru. Review key sessions, networking opportunities, insights gained. [10]",
            badges: ["🔥 High Yield", "📊 Report"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 158", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=158"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write an incident report (letter type) about a fire accident in Computer Science Lab – causes, actions, recommendations. [15]",
            badges: ["📋 Long"],
            years: "Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 159", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=159"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a precis of the given passage (bullying & long‑term effects – 600 words to ~200 words). Provide a suitable title. [10]",
            badges: ["🔥 High Yield", "🧮 Summarising"],
            years: "Dec 25 Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 157", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=157"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Calculate the Fog Index of the passage: \"Opinions differ on the right time to get an MBA...\". Show all steps (average sentence length, percentage of complex words, final index). [10]",
            badges: ["🧮 Numerical"],
            years: "Apr 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 157", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=157"},
          {"label": "📝 Exam Pg 19", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write an order letter to a supplier for purchasing laboratory equipment (as Purchase Manager). Mention quantity, specifications, delivery, payment. [15]",
            badges: ["📋 Long", "📊 Letter"],
            years: "Dec 25 Apr 25",
            links: [
          {"label": "📘 Course Pg 153", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=153"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a letter of complaint to the Manager of Shae Sales, Paldi, Ahmedabad about a television with internet connectivity and motherboard issues bought two months ago. [12]",
            badges: ["📊 Complaint"],
            years: "Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 153", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=153"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "✏️ ADDITIONAL TOPICS: DESCRIPTIVE & NARRATIVE WRITING",
        questions: [
          QuestionItem(
            title: "Write a technical description of a laptop computer following the 8‑step structure (Title, Introduction, Physical description, Components, Working principle, Specifications, Applications, Conclusion). [15]",
            badges: ["🔥 High Yield", "📊 Format"],
            years: "Dec 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 151", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=151"},
          {"label": "📝 Exam Pg 24", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=24"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Write a narrative essay on \"how technology has enhanced or hindered your learning experience\". [10]",
            badges: ["🔹 Rare", "📖 Essay"],
            years: "Dec 25",
            links: [
          {"label": "📘 Course Pg 160", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=160"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "As student representative, compose a 2‑page internal proposal to the Dean for approval of a tech club – benefits, proposed tasks, expenses. [12]",
            badges: ["🔹 Rare", "📊 Proposal"],
            years: "Apr 24",
            links: [
          {"label": "📘 Course Pg 159", "url": "/imp_pdf/written_comm/1HS102 full course.pdf#page=159"},
          {"label": "📝 Exam Pg 15", "url": "/imp_pdf/written_comm/1HS102 question bank.pdf#page=15"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Mathematics-I",
    code: "1MH101CC25",
    semester: "Semester 1",
    topicCount: 12,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.info,
    stats: ["📘 4 Modules", "🔢 50+ Solved Matrices", "🔥 High Yield Marked", "💎 Rare Concepts Included"],
    units: [
      UnitSection(
        title: "1. Matrices & Linear Systems",
        questions: [
          QuestionItem(
            title: "Find Rank by reducing to Row Echelon Form.",
            badges: ["Calc"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/maths/1MH101.pdf#page=1"},
            ],
            answer: "Method:\n                1. Use elementary row operations (R2 -> R2 - kR1) to make zeros below pivot.\n                2. Convert to Upper Triangular Matrix.\n                3. Rank = Number of Non-Zero Rows.",
            formula: "Specific Matrices Asked:\n                [1 2 -3 1 -6; 1 1 2 -1 7...]\n                [3 2 -3 1 -6; -1 3 2 -2 5...]\n                [0 1 -3 -1; 1 0 1 1...]",
          ),
          QuestionItem(
            title: "Consistency: Find values of α, β (or a, b) for Unique/Infinite/No Solution.",
            badges: ["High Yield"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/maths/1MH101.pdf#page=1"},
            ],
            answer: "Conditions:\n                • Unique: Rank(A) = Rank(A|B) = n (variables).\n                • Infinite: Rank(A) = Rank(A|B) < n.\n                • No Solution: Rank(A) ≠ Rank(A|B).",
            formula: "",
          ),
          QuestionItem(
            title: "Inverse of Matrix using Gauss-Jordan Method.",
            badges: ["Calc"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "Method:\n                1. Augment matrix A with Identity matrix I: [A | I].\n                2. Apply row operations to convert A into I: [I | A⁻¹].\n                3. The right side is the Inverse.",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "2. Vector Spaces",
        questions: [
          QuestionItem(
            title: "Check if set W is a Subspace/Vector Space.",
            badges: ["Concept"],
            years: "Feb 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/maths/1MH101.pdf#page=1"},
            ],
            answer: "Subspace Test:\n                1. Is Zero vector in W?\n                2. Is W closed under addition? (u+v in W)\n                3. Is W closed under scalar multiplication? (ku in W)",
            formula: "",
          ),
          QuestionItem(
            title: "Basis Extension & Reduction.",
            badges: ["High Yield"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "Extension: Add standard basis vectors to the set, check independence, form matrix, reduce to echelon, pick pivot columns.\nReduction: Form matrix with vectors as rows, reduce to echelon, non-zero rows form basis.",
            formula: "",
          ),
          QuestionItem(
            title: "Transition Matrix (P) & Coordinate Vectors [w].",
            badges: ["Calc"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "",
            formula: "Transition Matrix P (B' to B):\n                [ [v1]_B  [v2]_B ... [vn]_B ]\nCoordinate Change: [x]_B = P * [x]_B'",
          ),
        ],
      ),
      UnitSection(
        title: "3. Linear Transformations",
        questions: [
          QuestionItem(
            title: "Find Standard Matrix (Rotation, Dilation, Reflection).",
            badges: ["Calc"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "",
            formula: "Rotation (2D): [[cosθ -sinθ], [sinθ cosθ]]\nDilation (k): [[k 0], [0 k]]\nReflection (x-axis): [[1 0], [0 -1]]",
          ),
          QuestionItem(
            title: "Kernel, Range & Dimension Theorem.",
            badges: ["Concept"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "Dimension Theorem (Rank-Nullity):\n                Dim(V) = Rank(T) + Nullity(T)\nKernel: Solve T(x)=0.\nRange: Col space of Standard Matrix.",
            formula: "",
          ),
          QuestionItem(
            title: "Inverse of Linear Transformation.",
            badges: ["Calc"],
            years: "July 25, Feb 25, June 23",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/maths/1MH101.pdf#page=19"},
            ],
            answer: "Steps:\n                1. Find standard matrix A.\n                2. Find A⁻¹.\n                3. Define T⁻¹ using A⁻¹.",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "4. Eigenvalues & Diagonalization",
        questions: [
          QuestionItem(
            title: "Algebraic & Geometric Multiplicity.",
            badges: ["High Yield"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "Algebraic (AM): Number of times λ repeats as root.\nGeometric (GM): Dim(Eigenspace) = n - Rank(A-λI).\n                Matrix is diagonalizable iff AM = GM for all λ.",
            formula: "",
          ),
          QuestionItem(
            title: "Verify Cayley-Hamilton Theorem. Find A⁻¹ or Aⁿ.",
            badges: ["Calc"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24",
            links: [
          {"label": "Pg 2", "url": "imp_pdf/maths/1MH101.pdf#page=2"},
            ],
            answer: "Theorem: Every square matrix satisfies its own characteristic equation.\n                If λ³ - 6λ² + 11λ - 6 = 0, then A³ - 6A² + 11A - 6I = 0.\n                Multiply by A⁻¹ to find Inverse.",
            formula: "",
          ),
          QuestionItem(
            title: "Diagonalize Matrix A (Find P).",
            badges: ["Long"],
            years: "Apr 25, Feb 25, July 25, May 24, Mar 24, Feb 24, June 23",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/maths/1MH101.pdf#page=3"},
            ],
            answer: "",
            formula: "P = [v1 v2 v3] (Eigenvectors)\n                D = P⁻¹AP (Diagonal matrix with Eigenvalues)",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Mathematics-II",
    code: "1MH201CC25",
    semester: "Semester 1",
    topicCount: 27,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.square_grid_2x2,
    stats: ["📘 6 Modules", "🔢 27 Topics"],
    units: [
      UnitSection(
        title: "📐 UNIT I: INFINITE SEQUENCES & SERIES",
        questions: [
          QuestionItem(
            title: "Check convergence: \\(\\sum_{n=1}^{\\infty} \\frac{n}{(n+1)(n+2)(n+3)}\\) [06]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Dec 25 Apr 24 Feb 24",
            links: [
          {"label": "📘 Course Pg 19", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=19"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Examine convergence: \\(\\sum_{n=1}^{\\infty} \\frac{n!}{(2n+1)!}\\) [06]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Dec 23 Jun 24",
            links: [
          {"label": "📘 Course Pg 27", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=27"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Test convergence of series: \\(\\sum_{n=1}^{\\infty} \\frac{2n^2+3n}{5+n^5}\\) [06]",
            badges: ["🧮 Numerical"],
            years: "Feb 24 Dec 25",
            links: [
          {"label": "📘 Course Pg 21", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=21"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Find Maclaurin’s expansion of \\(f(x) = \\ln(1+4x)\\) upto \\(x^4\\) terms. [06]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 58", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=58"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Maclaurin’s series for \\(e^{x}\\sin x\\) up to \\(x^3\\) term. [07]",
            badges: ["📋 Detailed"],
            years: "Dec 25 Feb 23",
            links: [
          {"label": "📘 Course Pg 61", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=61"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Expand \\(\\tan^{-1}(y/x)\\) in powers of \\((x-1)\\) and \\((y-1)\\) using Taylor’s theorem. [07]",
            badges: ["📊 Algorithm"],
            years: "Apr 24 Dec 25",
            links: [
          {"label": "📘 Course Pg 151", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=151"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🧮 UNIT II: PARTIAL DIFFERENTIATION",
        questions: [
          QuestionItem(
            title: "If \\(u = \\ln\\left(\\frac{x^7+y^7+z^7}{x+y+z}\\right)\\), find \\(x\\frac{\\partial u}{\\partial x}+y\\frac{\\partial u}{\\partial y}+z\\frac{\\partial u}{\\partial z}\\). [06]",
            badges: ["🔥 High Yield", "📖 Euler"],
            years: "Apr 25 Dec 24 Jun 24",
            links: [
          {"label": "📘 Course Pg 115", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=115"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "If \\(u = \\sec^{-1}\\left(\\frac{x^3-y^3}{x+y}\\right)\\), show \\(x\\frac{\\partial u}{\\partial x}+y\\frac{\\partial u}{\\partial y}=2\\cot u\\) and evaluate \\(x^2 u_{xx}+2xy u_{xy}+ y^2 u_{yy}\\). [06]",
            badges: ["📋 Long"],
            years: "Dec 25 Feb 24",
            links: [
          {"label": "📘 Course Pg 113", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=113"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "If \\(z = xy^2 + x^2y\\), \\(x = at^2\\), \\(y=2at\\), find \\(\\frac{dz}{dt}\\). [06]",
            badges: ["🧮 Numerical"],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 127", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=127"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "If \\(u = f(y-z, z-x, x-y)\\), prove \\(\\frac{\\partial u}{\\partial x}+\\frac{\\partial u}{\\partial y}+\\frac{\\partial u}{\\partial z}=0\\). [07]",
            badges: ["📖 Theory"],
            years: "Feb 24 Dec 25",
            links: [
          {"label": "📘 Course Pg 141", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=141"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📈 UNIT III: APPLICATIONS OF PARTIAL DERIVATIVES",
        questions: [
          QuestionItem(
            title: "Find equations of tangent plane & normal line to surface \\(2x^2 + y^2 + 2z = 3\\) at point \\((2,1,-3)\\). [06]",
            badges: ["📊 Diagram"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 158", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=158"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Find extreme values of \\(f(x,y)=x^3+3xy^2-3x^2-3y^2+7\\). [07]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Dec 25 Apr 24 Jun 24",
            links: [
          {"label": "📘 Course Pg 167", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=167"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Examine maxima/minima of \\(f(x,y) = x^3 + y^3 - 3axy\\). [07]",
            badges: ["📋 Detailed"],
            years: "Feb 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 172", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=172"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Find maximum value of \\(x^2 y^3 z^4\\) subject to \\(2x+3y+4z = a\\) using Lagrange’s multipliers. [07]",
            badges: ["🔥 High Yield", "📖 Optimization"],
            years: "Dec 25 Jun 24 Apr 24",
            links: [
          {"label": "📘 Course Pg 183", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=183"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "A rectangular solid without lid from \\(12 m^2\\) cardboard: maximize volume. [06]",
            badges: ["🧮 Numerical"],
            years: "Feb 23 Apr 25",
            links: [
          {"label": "📘 Course Pg 185", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=185"},
          {"label": "📝 Exam Pg 13", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=13"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📊 UNIT IV: IMPROPER INTEGRALS & SPECIAL FUNCTIONS",
        questions: [
          QuestionItem(
            title: "Evaluate \\(\\int_0^{\\infty} x^5 e^{-3x} dx\\) using Gamma function. [06]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Apr 25 Dec 23 Feb 24",
            links: [
          {"label": "📘 Course Pg 188", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=188"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Show that \\(\\int_0^{\\pi/2} \\tan^p x \\, dx = \\frac{\\pi}{2}\\sec\\frac{p\\pi}{2}\\) and state restriction on p. [06]",
            badges: ["📖 Theory", "📊 Derivation"],
            years: "Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 196", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=196"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate \\(\\int_{0}^{1} x^4 (1-\\sqrt{x})^5 dx\\) using Beta function. [06]",
            badges: ["📋 Long"],
            years: "Jun 23 Dec 25",
            links: [
          {"label": "📘 Course Pg 198", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=198"},
          {"label": "📝 Exam Pg 6", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate \\(\\int_{0}^{\\infty} \\frac{x^{8}(1-x^{6})}{(1+x)^{24}}dx\\). [06]",
            badges: ["🔹 Rare"],
            years: "Apr 24",
            links: [
          {"label": "📘 Course Pg 200", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=200"},
          {"label": "📝 Exam Pg 21", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=21"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🌐 UNIT V: MULTIPLE INTEGRALS (DOUBLE & TRIPLE)",
        questions: [
          QuestionItem(
            title: "Change order of integration: \\(\\int_0^1 \\int_0^x e^{y^2} dy dx\\) and evaluate. [06]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Dec 25 Apr 24 Feb 24",
            links: [
          {"label": "📘 Course Pg 246", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=246"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate \\(\\int_0^2\\int_0^{\\sqrt{4-x^2}} (x^2+y^2) dy dx\\) by changing to polar coordinates. [06]",
            badges: ["📊 Polar"],
            years: "Apr 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 255", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=255"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Find volume of solid bounded by coordinate planes & plane \\(x+y+z=1\\). [06]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Dec 25 Feb 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 266", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=266"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Use double integration to find area between parabolas \\(y^2 = 36x\\) and \\(x^2 = 36y\\). [06]",
            badges: ["📋 Long", "📊 Area"],
            years: "Apr 24 Dec 25",
            links: [
          {"label": "📘 Course Pg 262", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=262"},
          {"label": "📝 Exam Pg 14", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=14"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Volume of solid generated by revolving \\(y = 2-x^2\\) about y-axis from \\(x=0\\) to \\(x=2\\). [06]",
            badges: ["📖 Revolution"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 217", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=217"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate \\(\\iiint_R (x^2+y^2+z^2) dxdydz\\) where R is region \\(x=0,y=0,z=0, x+y+z=a\\). [07]",
            badges: ["🔥 High Yield", "🧮 Triple"],
            years: "Dec 24 Apr 25 Feb 23",
            links: [
          {"label": "📘 Course Pg 275", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=275"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📏 ADDITIONAL TOPICS: SURFACE AREA OF REVOLUTION",
        questions: [
          QuestionItem(
            title: "Find surface area generated by revolving curve \\(y = e^x\\), \\(0\\le x\\le 1\\) about x-axis. [07]",
            badges: ["📊 Diagram", "📋 Long"],
            years: "Dec 25 Apr 24",
            links: [
          {"label": "📘 Course Pg 231", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=231"},
          {"label": "📝 Exam Pg 12", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=12"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Arc of \\(y = \\sqrt{4-x^2}\\) from \\(-1\\) to \\(1\\) revolved about x-axis: find surface area. [07]",
            badges: ["🧮 Numerical"],
            years: "Feb 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 229", "url": "/imp_pdf/maths_2/1MH201 full course.pdf#page=229"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/maths_2/1MH201 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Statistics",
    code: "1MH301CC25",
    semester: "Semester 1",
    topicCount: 28,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.square_grid_2x2,
    stats: ["📘 6 Modules", "🔢 28 Topics"],
    units: [
      UnitSection(
        title: "🎲 UNIT I: PROBABILITY THEORY & RANDOM VARIABLES",
        questions: [
          QuestionItem(
            title: "Shaft A and B are tested independently. P(A conforms)=1/7, P(B conforms)=1/5. Find i) both conform ii) exactly one conforms iii) at least one conforms. [06]",
            badges: ["🔥 High Yield", "🧮 Numerical"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 244", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=244"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Medical symptoms: illnesses A,B,C with prior probabilities 0.01,0.005,0.02. Symptom H probabilities 0.90,0.95,0.75. If a person shows H, find P(illness A). [06]",
            badges: ["🔥 High Yield", "📖 Bayes"],
            years: "Apr 25 Dec 23 Aug 23",
            links: [
          {"label": "📘 Course Pg 286", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=286"},
          {"label": "📝 Exam Pg 34", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=34"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Random arrangement of letters of \"INDEPENDENCE\". Probability that all vowels are together. [06]",
            badges: ["🔹 Rare", "📊 Permutation"],
            years: "Apr 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 262", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=262"},
          {"label": "📝 Exam Pg 34", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=34"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "The probability mass function: X=0..6 with p(x)=k,0.12,0.25,0.188,k,0.14,0.06. Find k, mean, variance. [06]",
            badges: ["🔥 High Yield", "🧮 Expectation"],
            years: "Apr 25 Dec 24 Feb 24",
            links: [
          {"label": "📘 Course Pg 309", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=309"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Continuous random variable X with p.d.f. f(x)=k(1+x), 2≤x≤5. Find P(X<4). [06]",
            badges: ["🧮 PDF"],
            years: "Dec 23 Apr 24",
            links: [
          {"label": "📘 Course Pg 303", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=303"},
          {"label": "📝 Exam Pg 22", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📈 UNIT II: DISCRETE & CONTINUOUS DISTRIBUTIONS",
        questions: [
          QuestionItem(
            title: "Four cards drawn from a well‑shuffled pack without replacement. Probability that (i) all are diamonds (ii) one card of each suit (iii) two spades and two hearts. [06]",
            badges: ["🔥 High Yield", "🧮 Combination"],
            years: "Apr 25 Dec 23 Jun 24",
            links: [
          {"label": "📘 Course Pg 327", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=327"},
          {"label": "📝 Exam Pg 30", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=30"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "A speaks truth 70%, B 85%. Find percentage of cases they contradict each other stating same fact. [06]",
            badges: ["🔥 High Yield", "📖 Probability"],
            years: "Apr 25 Dec 24 Feb 23",
            links: [
          {"label": "📘 Course Pg 325", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=325"},
          {"label": "📝 Exam Pg 18", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "In a batch of 5000 components, 100 are defective. A box of 100 components is selected. Using Poisson approximation, find i) P(at most 3 defective) ii) P(at least 2 defective) iii) P(between 2 and 5 inclusive). [07]",
            badges: ["🔥 High Yield", "🧮 Poisson"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 340", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=340"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "A manufacturer of medicine bottles finds 0.1% defective. Bottles packed in boxes of 500. A drug manufacturer buys 100 boxes. Find how many boxes contain (i) no defectives (ii) at least two defectives. [07]",
            badges: ["📋 Long", "🧮 Poisson"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 350", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=350"},
          {"label": "📝 Exam Pg 35", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=35"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Wait times at drive‑through: normal with mean 185 sec, σ=15 sec. Find percentage of wait times i) between 155 and 215 sec ii) more than 170 sec iii) less than 155 sec. [07]",
            badges: ["🔥 High Yield", "🧮 Z‑table"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 364", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=364"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Life of electronic device: mean 300 hours, σ=25 hours. (i) probability life more than 350 hours (ii) percentage between 220 and 260 hours. [07]",
            badges: ["🧮 Normal"],
            years: "Dec 23 Apr 25",
            links: [
          {"label": "📘 Course Pg 378", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=378"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📉 UNIT III: CORRELATION & REGRESSION ANALYSIS",
        questions: [
          QuestionItem(
            title: "A computer calculated correlation with n=30, ΣX=120, ΣX²=600, ΣY=90, ΣY²=250, ΣXY=335 but two pairs were wrong: (8,10) and (12,7) should be (8,12) and (10,8). Find the correct value of r. [06]",
            badges: ["🔥 High Yield", "🧮 Correction"],
            years: "Apr 25 Dec 24 Jun 24",
            links: [
          {"label": "📘 Course Pg 117", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=117"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "From the following data calculate Karl Pearson’s coefficient: x: 17,19,21,26,20,28,26,27 ; y: 23,27,25,26,27,25,30,33. [06]",
            badges: ["📋 Long", "🧮 Correlation"],
            years: "Feb 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 108", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=108"},
          {"label": "📝 Exam Pg 23", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=23"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Ten students thesis marks by two judges: Judge1: 26,28,18,26,22,26,18,20,21,29 ; Judge2: 25,22,22,25,22,28,22,23,24,27. Compute Spearman’s rank correlation coefficient. [06]",
            badges: ["📊 Rank"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 133", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=133"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Regression lines: 40x−18y−214=0 and 8x−10y+66=0. Find mean(x), mean(y), correlation coefficient, and estimate x when y=20. [06]",
            badges: ["🔥 High Yield", "🧮 Regression"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 196", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=196"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Find regression lines and estimate y when x=66, x when y=74 from data: x:57,58,59,59,60,61,62,64 ; y:67,68,65,68,72,72,69,71. [07]",
            badges: ["📋 Long", "🧮 Linear regression"],
            years: "Dec 23 Apr 24",
            links: [
          {"label": "📘 Course Pg 199", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=199"},
          {"label": "📝 Exam Pg 20", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📐 UNIT IV: CURVE FITTING & DESCRIPTIVE STATISTICS",
        questions: [
          QuestionItem(
            title: "Fit a curve of the form y = a·x^b to the data: x:2,4,6,8,10,12,20,25 ; y:40,320,1080,2560,5000,8640,40000,78125. Estimate y when x=9.5. [06]",
            badges: ["🧮 Power curve"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 235", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=235"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Fit exponential curve y = a·b^x by least squares to: x:1,2,3,4,5 ; y:7.12,7.86,2.11,10,161 (data approximate). [06]",
            badges: ["🔹 Rare", "📖 Exponential"],
            years: "Feb 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 230", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=230"},
          {"label": "📝 Exam Pg 36", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=36"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "From grouped frequency table (marks 0-12 to 108-120 with frequencies: 2,2,3,5,21,44,35,56,32,45,42,57), compute median and modal marks. [06]",
            badges: ["🔥 High Yield", "🧮 Central tendency"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 25", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=25"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compute standard deviation for IQ of 50 boys: classes 0-20,20-40,...,140-160 with frequencies 3,4,3,4,13,12,8,3. [06]",
            badges: ["📊 Dispersion"],
            years: "Dec 23 Apr 24",
            links: [
          {"label": "📘 Course Pg 58", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=58"},
          {"label": "📝 Exam Pg 8", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=8"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🔬 UNIT V: HYPOTHESIS TESTING (Large & Small Samples)",
        questions: [
          QuestionItem(
            title: "Last year proportion of defective items 0.022. This year sample of 250 items, 7 defective. Test if proportion has changed (α=0.05). Find p‑value. [07]",
            badges: ["🔥 High Yield", "🧮 Proportion test"],
            years: "Apr 25 Dec 24 Feb 24",
            links: [
          {"label": "📘 Course Pg 428", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=428"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Packaging machine set to mean weight 5 kg, σ=0.21 kg. Sample of 100 packets mean = 5.03 kg. Can we conclude mean weight has increased? Use 5% level. [07]",
            badges: ["🔥 High Yield", "🧮 Z‑test"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 419", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=419"},
          {"label": "📝 Exam Pg 9", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Farmer claims yield >14 quintals. Sample yields: 14.3,12.6,13.7,10.9,13.7,12.0,11.4,12.0,13.0,12.8. Test the claim at 5% significance level. [07]",
            badges: ["📋 Long", "🧮 One‑sample t"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 450", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=450"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "A machine designed to produce washers of average thickness 0.025 cm. Sample of 10 washers: mean 0.024 cm, s=0.002 cm. Test significance of deviation at 5% level. [07]",
            badges: ["🧮 t‑test"],
            years: "Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 450", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=450"},
          {"label": "📝 Exam Pg 36", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=36"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Sample of 100 iron bars mean length 4.2 ft, population mean 4 ft, σ=0.5 ft. Can the sample be regarded as truly random at 5% significance level? [07]",
            badges: ["🔹 Rare", "🧮 Z‑test"],
            years: "Apr 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 426", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=426"},
          {"label": "📝 Exam Pg 36", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=36"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📌 ADDITIONAL HIGH‑YIELD TOPICS",
        questions: [
          QuestionItem(
            title: "Microchips: 5% defective. Box of 1000, guarantee not more than 10 defective. Approximate probability that a box fails the guarantee using Poisson approximation. [07]",
            badges: ["📋 Long", "🧮 Poisson"],
            years: "Dec 23 Apr 24",
            links: [
          {"label": "📘 Course Pg 351", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=351"},
          {"label": "📝 Exam Pg 19", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "1000 light bulbs, mean life 120 days, σ=20 days, normally distributed. How many bulbs expire in less than 90 days? Between 110 and 125 days? [07]",
            badges: ["🧮 Normal"],
            years: "Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 378", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=378"},
          {"label": "📝 Exam Pg 35", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=35"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Fit second‑degree parabola y = a + bx + cx² to data: x:0,1,2,3,4 ; y:1,3,4,5,6 using least squares. [07]",
            badges: ["📊 Polynomial"],
            years: "Apr 24 Dec 23",
            links: [
          {"label": "📘 Course Pg 208", "url": "/imp_pdf/statics/1MH301 full course.pdf#page=208"},
          {"label": "📝 Exam Pg 20", "url": "/imp_pdf/statics/1MH301 question bank.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Contemporary India",
    code: "1MU801CC25",
    semester: "Semester 1",
    topicCount: 21,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.flag,
    stats: ["📘 5 Modules", "🔢 21 Topics"],
    units: [
      UnitSection(
        title: "🏛️ UNIT I: INDIA GETS INDEPENDENCE – POLITICAL ASPECTS",
        questions: [
          QuestionItem(
            title: "Define Democracy. What is the Nature of Democracy in India? Do you think Coalitions have strengthened or weakened Indian Democracy? [17]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Feb 25 Dec 24 Jun 23 May 24",
            links: [
          {"label": "📘 Course Pg 33", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=33"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Examine the Role of Election Commission of India in facilitating free & fair Elections. How does it contribute towards a strong democracy? [17]",
            badges: ["🔥 High Yield", "📊 Institution"],
            years: "Apr 25 May 24 Feb 25 Dec 23",
            links: [
          {"label": "📘 Course Pg 41", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=41"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is Secularism? Do you think India has sustained secular traditions in its constitutional and political spirit throughout its independent history as well as in contemporary times? [17]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 22", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=22"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "\"Nationalism is built on a belief that a group of people are bound by common characteristics like language, history, culture, or religion.\" Analyze this statement in view of the concept of Nationalism and Sub‑Nationalism(s) in India. Distinguish among the various types of Nationalism(s) in India with suitable examples. [10+5]",
            badges: ["📋 Long", "📊 Types"],
            years: "Apr 25 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 12", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=12"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📈 UNIT II: INDIA GETS INDEPENDENCE – ECONOMIC ASPECTS",
        questions: [
          QuestionItem(
            title: "Why was Planning Commission set‑up in India after 1947? How is it different from NITI Aayog in terms of its functioning, objectives and composition? [17]",
            badges: ["🔥 High Yield", "📊 Comparison"],
            years: "Apr 25 Feb 25 Dec 24 May 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 52", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=52"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Critically Analyze the functioning and objectives of NITI Aayog. How does it facilitate the objectives of e‑Governance in India? State its achievements & failures. [17]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 May 24 Feb 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 58", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=58"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Evaluate the role played by LPG 1991 to transition India from a closed‑economy to a more market‑driven one, laying foundations for long‑term economic growth and industrial development. [10]",
            badges: ["🔥 High Yield", "🧮 Data"],
            years: "Apr 25 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 48", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=48"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compare and contrast between the concepts of Liberalisation, Privatisation and Globalisation in the Indian Context. [10]",
            badges: ["📊 Comparison"],
            years: "Apr 25 Feb 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 49", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=49"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What do you understand by \"Digital Economy\"? How is it different from the Traditional Economy? Has the Digital Economy registered growth in India's GDP over the last decade? [16]",
            badges: ["📋 Long", "🧮 GDP"],
            years: "Dec 24 Jun 23 Apr 25",
            links: [
          {"label": "📘 Course Pg 62", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=62"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🎨 UNIT III: SOCIETY & CULTURE",
        questions: [
          QuestionItem(
            title: "Discuss the need to preserve various kinds of arts & culture in India. What are their diverse types? Do they have a relation with Environmental Sustainability? [17]",
            badges: ["🔥 High Yield", "📊 Art forms"],
            years: "Apr 25 May 24 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 28", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=28"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain the kinds of Arts and Art‑Forms of Indian Cultural Heritage. Do you think they need to be preserved & protected with regard to rich ancient Indian Historical Civilization? [17]",
            badges: ["📋 Long", "📖 Theory"],
            years: "Apr 25 May 24 Feb 25",
            links: [
          {"label": "📘 Course Pg 29", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=29"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is traditional hierarchy of caste‑system in India? Do you agree that Caste is becoming weaker and stronger at the same time? What do you understand by Caste‑Mobility? [17]",
            badges: ["🔥 High Yield", "📖 Theory"],
            years: "Apr 25 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 19", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=19"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Identify the Caste‑based hierarchical classification. Develop a balanced argumentative position regarding the Reservation Policy in India based upon Caste. [10]",
            badges: ["📋 Long", "📊 Debate"],
            years: "Feb 25 Dec 24 Apr 25",
            links: [
          {"label": "📘 Course Pg 21", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=21"},
          {"label": "📝 Exam Pg 3", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "🌍 UNIT IV: CONTEMPORARY CHALLENGES & GOVERNANCE",
        questions: [
          QuestionItem(
            title: "What do you interpret by Women Empowerment? Is it an idea existing only in Modern India? Outline the Central Government Schemes for ensuring Women Empowerment in India. Have they been successful? [10+7]",
            badges: ["🔥 High Yield", "📖 Schemes"],
            years: "Apr 25 Feb 25 May 24 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 37", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=37"},
          {"label": "📝 Exam Pg 5", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Examine with Examples, the distinction between Good Governance and E‑Governance in India. [05]",
            badges: ["🔥 High Yield", "📊 Comparison"],
            years: "Apr 25 Feb 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 44", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=44"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define e‑Governance. How do Digital India and Good‑Governance further enhance the aims and objectives of e‑Governance? [17]",
            badges: ["📋 Long", "📖 Framework"],
            years: "May 24 Feb 25 Apr 25",
            links: [
          {"label": "📘 Course Pg 45", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=45"},
          {"label": "📝 Exam Pg 4", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate between Foreign Policy of Nehru with that of PM Modi. How has Foreign Policy under PM Modi facilitated an image of \"Cultural Diplomacy\" for India? Critically analyze his policy in recent international dynamics. [16]",
            badges: ["🔥 High Yield", "📊 Comparison"],
            years: "Apr 25 May 24 Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 26", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=26"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Demonstrate clearly any one Tribal Conflict in India that has had significant consequences on the ethnicity paradigm of that State as well as deemed‑intervention from the Centre. Has any government been able to resolve the conflict‑in‑question? [10]",
            badges: ["🔹 Rare", "📋 Case Study"],
            years: "Feb 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 39", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=39"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "📘 ADDITIONAL HIGH‑YIELD & MIXED TOPICS",
        questions: [
          QuestionItem(
            title: "How did Five‑Year Plans facilitate the development of India post‑Independence? Discuss their objectives. How was the Planning Commission set up? [16]",
            badges: ["🔥 High Yield", "🧮 Historical"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 50", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=50"},
          {"label": "📝 Exam Pg 1", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Make an Analysis of Good Governance Concept in the Indian Context, highlighting the difference from erstwhile prevailing concept of Governance. Justify with Examples. [10]",
            badges: ["📋 Long", "📖 Theory"],
            years: "Feb 25 Apr 25 Dec 24",
            links: [
          {"label": "📘 Course Pg 44", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=44"},
          {"label": "📝 Exam Pg 2", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=2"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Define Democracy. Do you think Coalitions have strengthened or weakened Indian Democracy? (variation) [17]",
            badges: ["🔥 High Yield", "📊 Debate"],
            years: "Apr 25 Dec 24 Jun 23",
            links: [
          {"label": "📘 Course Pg 35", "url": "/imp_pdf/contemp_india/1MU801 full course.pdf#page=35"},
          {"label": "📝 Exam Pg 7", "url": "/imp_pdf/contemp_india/1MU801 question bank.pdf#page=7"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
  SubjectItem(
    name: "Physics",
    code: "1SP201CC25",
    semester: "Semester 1",
    topicCount: 34,
    gradient: [Color(0xFFE11D48), Color(0xFF9F1239)],
    icon: CupertinoIcons.sparkles,
    stats: ["📘 6 Modules", "🔥 20 High-Yield Topics", "✏️ 10+ Diagrams", "💎 Rare Questions Included"],
    units: [
      UnitSection(
        title: "1. Lasers & Fiber Optics",
        questions: [
          QuestionItem(
            title: "Explain construction and working of Semiconductor Laser.",
            badges: ["Diagram", "High Yield"],
            years: "Dec 24 Dec 23",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/physics/1SP201.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain CO2 Laser construction/working.",
            badges: [],
            years: "Feb 25 July 24",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/physics/1SP201.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Ruby Laser with diagram. Limitations?",
            badges: [],
            years: "Aug 23 June 23 May 24",
            links: [
          {"label": "Pg 1", "url": "imp_pdf/physics/1SP201.pdf#page=1"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain 3-Level / 4-Level Laser Systems. Principles & Drawbacks.",
            badges: ["Repeat"],
            years: "July 25 Apr 25 July 24 May 24",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/physics/1SP201.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is Pumping? Types/Importance. What is Optical Resonator?",
            badges: ["Repeat"],
            years: "July 25 Dec 24 July 24 Dec 23 May 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/physics/1SP201.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Stimulated Absorption, Spontaneous vs Stimulated Emission.",
            badges: ["2-Level Sys"],
            years: "Feb 25 Apr 25",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/physics/1SP201.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Why LASER acronym should be LOSER?",
            badges: ["Unique"],
            years: "Feb 24",
            links: [
          {"label": "Pg 9", "url": "imp_pdf/physics/1SP201.pdf#page=9"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Describe Optical Fiber Communication Link (Block diagram/Flow).",
            badges: ["Diagram", "High Yield"],
            years: "Apr 25 Dec 24 Feb 24 May 24 June 23",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/physics/1SP201.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differentiate: Step Index vs Graded Index / Core vs Cladding.",
            badges: ["Repeat"],
            years: "Feb 25 Apr 25 July 24 June 23",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/physics/1SP201.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Fiber Sensors: Intensity Modulated (Temp/Force/Liquid Level).",
            badges: ["Applied"],
            years: "July 25 Feb 25 Apr 25 Dec 23 Aug 23",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/physics/1SP201.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "2. Quantum Mechanics",
        questions: [
          QuestionItem(
            title: "Derive energy/wavefunction for Particle in Infinite Square Well (1D Box).",
            badges: ["Diagram", "Top Repeat"],
            years: "July 25 Feb 25 Apr 25 Feb 24",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/physics/1SP201.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Derive Schrodinger's Equation (Time Dependent / Independent).",
            badges: [],
            years: "July 25 Dec 23 May 24",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/physics/1SP201.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Wave Function: Concept, Postulates, Characteristics, Normalization.",
            badges: [],
            years: "Feb 25 Apr 25 Dec 24 May 24",
            links: [
          {"label": "Pg 3", "url": "imp_pdf/physics/1SP201.pdf#page=3"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Differences: Classical vs Quantum Mechanics.",
            badges: [],
            years: "July 25 July 24",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/physics/1SP201.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "3. Nanomaterials & Synthesis",
        questions: [
          QuestionItem(
            title: "Discuss Ball Milling technique. Advantages/Disadvantages.",
            badges: ["Diagram", "High Yield"],
            years: "July 25 Feb 25 July 24 Aug 23",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss Laser Ablation technique.",
            badges: [],
            years: "Apr 25 Dec 23 June 23",
            links: [
          {"label": "Pg 4", "url": "imp_pdf/physics/1SP201.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Discuss CVD (Chemical Vapor Deposition) / Sputtering / Sol-Gel.",
            badges: [],
            years: "Dec 24 Feb 24 May 24",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/physics/1SP201.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Explain Surface to Volume Ratio & Quantum Confinement.",
            badges: [],
            years: "Apr 25 July 24 Feb 24 Dec 23 June 23 May 24",
            links: [
          {"label": "Pg 4", "url": "imp_pdf/physics/1SP201.pdf#page=4"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Microscopy: SEM vs TEM. Construction & Working.",
            badges: ["Diagram"],
            years: "Dec 24 July 24 Dec 23 Aug 23",
            links: [
          {"label": "Pg 5", "url": "imp_pdf/physics/1SP201.pdf#page=5"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "CNTs (Carbon Nanotubes): Properties.",
            badges: [],
            years: "Feb 25 Dec 24 Aug 23",
            links: [
          {"label": "Pg 18", "url": "imp_pdf/physics/1SP201.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "4. Acoustics & Ultrasonics",
        questions: [
          QuestionItem(
            title: "Sabine's Formula & Reverberation Time control. Good Acoustics requirements.",
            badges: ["High Yield"],
            years: "July 25 Dec 24 July 24 Apr 25 Feb 24",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "What is 1 dB noise? Threshold of audibility. Sound wave characteristics.",
            badges: ["Rare"],
            years: "Dec 23 Aug 23 May 24",
            links: [
          {"label": "Pg 22", "url": "imp_pdf/physics/1SP201.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Production Methods: Reverse/Inverse Piezoelectric vs Magnetostriction.",
            badges: ["High Yield"],
            years: "July 25 Dec 24 Apr 25 Feb 24 Aug 23 June 23",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Applications: Cleaning, Acoustic Grating (Velocity determination).",
            badges: [],
            years: "Dec 24 July 24 Dec 23",
            links: [
          {"label": "Pg 6", "url": "imp_pdf/physics/1SP201.pdf#page=6"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "5. Semiconductors, Vacuum & Nuclear",
        questions: [
          QuestionItem(
            title: "Fermi Level: Significance, N/P-type behavior with Temperature.",
            badges: ["Graph", "Repeat"],
            years: "July 25 Feb 25 Apr 25 Dec 24 Feb 24 May 24",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Bandgap: Direct vs Indirect Bandgap difference. Molecular Orbital Theory (MOT).",
            badges: [],
            years: "Feb 25 Dec 24 July 24 Dec 23 June 23",
            links: [
          {"label": "Pg 18", "url": "imp_pdf/physics/1SP201.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Pumps & Detectors: Rotary vs Diffusion vs Ion Sputter Pumps. GM Counter vs Scintillation Counter.",
            badges: ["Diagram"],
            years: "July 25 Feb 25 Apr 25 Dec 24 July 24 Aug 23 Dec 23",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/physics/1SP201.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Accelerators: Linear vs Circular.",
            badges: ["Repeat"],
            years: "July 25 Feb 25 Apr 25",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Pirani Gauge (Low pressure measurement).",
            badges: ["Unique"],
            years: "Dec 23",
            links: [
          {"label": "Pg 22", "url": "imp_pdf/physics/1SP201.pdf#page=22"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
      UnitSection(
        title: "6. Numerical Problem Bank",
        questions: [
          QuestionItem(
            title: "Resultant Sound Intensity (dB): Adding dB levels (e.g., 80dB + 75dB).",
            badges: ["Top Repeat"],
            years: "July 25 Feb 25 Apr 25 Dec 24 July 24 May 24 Dec 23 June 23",
            links: [
          {"label": "Pg 20", "url": "imp_pdf/physics/1SP201.pdf#page=20"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Particle in Box: Find Energy, Momentum, Probability for Excited states.",
            badges: ["Top Repeat"],
            years: "July 25 Feb 25 Apr 25 Dec 24 July 24 May 24 June 23",
            links: [
          {"label": "Pg 18", "url": "imp_pdf/physics/1SP201.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Compton Scattering: Shift, Wavelength, Recoil Energy.",
            badges: [],
            years: "July 25 Apr 25 July 24 Feb 24 Dec 23 May 24 June 23",
            links: [
          {"label": "Pg 19", "url": "imp_pdf/physics/1SP201.pdf#page=19"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Fiber Optics: Calculate NA, Acceptance Angle, Cladding Index.",
            badges: [],
            years: "Feb 25 Dec 24 July 24 Dec 23 Aug 23 May 24 June 23",
            links: [
          {"label": "Pg 18", "url": "imp_pdf/physics/1SP201.pdf#page=18"},
            ],
            answer: "",
            formula: "",
          ),
          QuestionItem(
            title: "Laser: Spontaneous/Stimulated Ratio, Intensity calculation.",
            badges: [],
            years: "Feb 25 Apr 25 Dec 24 July 24 Feb 24 Dec 23 May 24 June 23",
            links: [
          {"label": "Pg 17", "url": "imp_pdf/physics/1SP201.pdf#page=17"},
            ],
            answer: "",
            formula: "",
          ),
        ],
      ),
    ],
  ),
];
