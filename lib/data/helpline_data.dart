/// Emergency helpline contact data for mental health crisis escalation.
library helpline_data;

class Helpline {
  final String name;
  final String number;
  final String hours;
  final String description;

  const Helpline({
    required this.name,
    required this.number,
    required this.hours,
    required this.description,
  });
}

class HelplineData {
  static const List<Helpline> helplines = [
    Helpline(
      name: "iCall (TISS)",
      number: "9152987821",
      hours: "Mon–Sat, 8 AM – 10 PM",
      description: "Free professional counselling for emotional distress.",
    ),
    Helpline(
      name: "Vandrevala Foundation",
      number: "1860-2662-345",
      hours: "24/7, Free",
      description: "24-hour mental health crisis support and counselling.",
    ),
    Helpline(
      name: "NIMHANS Helpline",
      number: "080-46110007",
      hours: "24/7",
      description: "National Institute of Mental Health crisis line.",
    ),
    Helpline(
      name: "Snehi",
      number: "044-24640050",
      hours: "Daily, 8 AM – 10 PM",
      description: "Emotional support for individuals in distress.",
    ),
  ];
}
