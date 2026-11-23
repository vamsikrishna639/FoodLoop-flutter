// One line of the activity feed, as returned by /api/activity.
// The server writes the sentence ("Ananya Rao requested 6 packets of ...")
// and already limits the feed to what this user is allowed to see.

class ActivityEvent {
  const ActivityEvent({required this.id, required this.kind, required this.text, required this.at});

  final String id; // stable, e.g. "requested-<claim id>", so new lines can be spotted
  final String kind; // posted | requested | approved | rejected | cancelled | assigned | picked_up | delivered
  final String text;
  final DateTime at;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: (json['id'] ?? '').toString(),
        kind: (json['kind'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
        at: DateTime.tryParse((json['at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      );
}
