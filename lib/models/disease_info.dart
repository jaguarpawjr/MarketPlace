class DiseaseInfo {
  final String title;
  final String description;
  final String symptoms;
  final String treatment;
  final String prevention;
  
  const DiseaseInfo({
    required this.title,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
  });
}

const Map<String, DiseaseInfo> diseaseData = {
  'Bacterial_spot': DiseaseInfo(
    title: 'Bacterial Spot',
    description: 'A bacterial disease caused by Xanthomonas species that affects foliage and fruit, potentially reducing yield significantly.',
    symptoms: 'Small, water-soaked spots on leaves that turn brown/black. Scab-like spots may appear on the fruit.',
    treatment: 'Copper-based fungicides can slow the spread, but severely infected plants should be removed to protect the rest of the crop.',
    prevention: 'Use disease-free seed, rotate crops, avoid overhead watering, and ensure good air circulation.',
  ),
  'Early_blight': DiseaseInfo(
    title: 'Early Blight',
    description: 'A common fungal disease caused by Alternaria solani, typically affecting older leaves first and thriving in warm, humid weather.',
    symptoms: 'Dark, concentric ring spots (bullseye pattern) on lower leaves, leading to yellowing, withering, and leaf drop.',
    treatment: 'Remove affected leaves immediately. Apply appropriate fungicides containing chlorothalonil or copper.',
    prevention: 'Stake plants for air circulation, apply mulch to prevent soil splashing onto lower leaves, and practice crop rotation.',
  ),
  'Late_blight': DiseaseInfo(
    title: 'Late Blight',
    description: 'A highly destructive water mold disease caused by Phytophthora infestans. It can destroy entire fields within days if unchecked.',
    symptoms: 'Large, dark, water-soaked lesions on leaves and stems. White fungal growth in humid conditions. Fruits develop dark, greasy spots.',
    treatment: 'Immediate removal and destruction of infected plants is crucial. Fungicides are mostly preventative and rarely cure an active infection.',
    prevention: 'Keep foliage dry, avoid overhead watering, and plant resistant varieties.',
  ),
  'Leaf_Mold': DiseaseInfo(
    title: 'Leaf Mold',
    description: 'A fungal disease caused by Passalora fulva, very common in high humidity environments like greenhouses or high tunnels.',
    symptoms: 'Pale greenish-yellow spots on the upper leaf surface, with characteristic olive-green to brown velvety mold on the underside.',
    treatment: 'Improve ventilation and reduce humidity. Fungicides can be applied at the first sign of disease.',
    prevention: 'Ensure proper plant spacing, prune lower leaves to increase airflow, and use drip irrigation.',
  ),
  'Septoria_leaf_spot': DiseaseInfo(
    title: 'Septoria Leaf Spot',
    description: 'A very common fungal disease caused by Septoria lycopersici affecting tomato foliage, often mistaken for Early Blight.',
    symptoms: 'Numerous small, circular spots with dark borders and grey/tan centers on lower leaves. Leaves quickly turn yellow and drop off.',
    treatment: 'Remove infected leaves immediately. Apply fungicidal sprays (like copper or chlorothalonil) to protect healthy tissue.',
    prevention: 'Mulch the base of plants, water strictly at the soil level, and practice a 3-year crop rotation.',
  ),
  'Spider_mites Two-spotted_spider_mite': DiseaseInfo(
    title: 'Two-Spotted Spider Mites',
    description: 'Tiny arachnids that feed on the sap of tomato plants. They multiply rapidly and thrive in hot, dry conditions.',
    symptoms: 'Stippling or tiny yellow/white dots on leaves. Fine webbing may be visible on the undersides of leaves. Leaves eventually dry and fall.',
    treatment: 'Spray thoroughly with insecticidal soap, neem oil, or horticultural oils. Introduce natural predators like ladybugs or predatory mites.',
    prevention: 'Maintain consistent soil moisture and keep dust down. Occasional strong sprays of water can dislodge mites.',
  ),
  'Target_Spot': DiseaseInfo(
    title: 'Target Spot',
    description: 'A fungal disease caused by Corynespora cassiicola that can affect all above-ground parts of the plant.',
    symptoms: 'Small, dark spots with concentric rings on leaves and stems, often resembling Early Blight but smaller. Fruit may develop pitted lesions.',
    treatment: 'Apply appropriate targeted fungicides. Remove severely affected foliage to reduce the spore load in the field.',
    prevention: 'Improve air circulation, avoid working among wet plants, and clear all crop debris immediately after harvest.',
  ),
  'Tomato_Yellow_Leaf_Curl_Virus': DiseaseInfo(
    title: 'Tomato Yellow Leaf Curl Virus',
    description: 'A devastating viral disease transmitted by the silverleaf whitefly. It severely stunts plant growth.',
    symptoms: 'Leaves curl upward, turn noticeably yellow at the edges, and become stunted. Plants stop growing and produce little to no fruit.',
    treatment: 'There is NO cure for the virus. Infected plants must be uprooted and destroyed immediately to prevent spread.',
    prevention: 'Control whitefly populations using yellow sticky traps or insecticidal soaps. Always plant resistant varieties in prone areas.',
  ),
  'Tomato_mosaic_virus': DiseaseInfo(
    title: 'Tomato Mosaic Virus',
    description: 'A highly contagious viral disease that can survive in seeds, soil, and on tools or hands for years.',
    symptoms: 'Light and dark green mottled (mosaic) pattern on leaves. Fern-like leaf distortion and overall stunted growth.',
    treatment: 'No cure exists. Remove and burn or safely dispose of infected plants. Do NOT compost infected plants.',
    prevention: 'Disinfect tools and hands regularly (especially if you use tobacco products). Plant TMV-resistant varieties.',
  ),
  'powdery_mildew': DiseaseInfo(
    title: 'Powdery Mildew',
    description: 'A fungal disease that surprisingly thrives in warm, dry climates, though it requires high humidity at the leaf surface to start.',
    symptoms: 'White, powdery fungal patches appear on leaves. Affected leaves may turn yellow and die prematurely.',
    treatment: 'Apply sulfur-based fungicides, potassium bicarbonate, or neem oil at first sight. Ensure thorough coverage.',
    prevention: 'Plant in full sun, space plants adequately for airflow, and avoid excessive nitrogen fertilizer which promotes susceptible leafy growth.',
  ),
  'healthy': DiseaseInfo(
    title: 'Healthy Plant',
    description: 'The plant is showing no visible signs of major diseases or severe pest infestations.',
    symptoms: 'Vibrant green leaves without unusual spots, yellowing, or curling. Stems are sturdy, and growth is vigorous.',
    treatment: 'No treatment needed. Keep up the excellent work!',
    prevention: 'Continue regular field monitoring, proper watering routines, and good crop management practices to maintain optimal plant health.',
  ),
};
