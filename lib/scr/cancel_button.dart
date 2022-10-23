part of lock_screen;

class LockScreenCancel extends StatelessWidget {
  static const none = LockScreenCancel._(button: SizedBox.shrink());

  const LockScreenCancel._({super.key, required this.button});

  const LockScreenCancel({super.key}) : button = const Icon(Icons.cancel);

  LockScreenCancel.text({Key? key, required String text})
      : this._(
          key: key,
          button: _padText(text),
        );

  LockScreenCancel.icon({Key? key, required Widget icon, String? text})
      : this._(
          key: key,
          button: text == null
              ? icon
              : TextButton.icon(
                  onPressed: () {},
                  icon: icon,
                  label: _padText(text),
                ),
        );

  final Widget button;

  @override
  Widget build(BuildContext context) => button;
}

Widget _padText(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text),
    );
