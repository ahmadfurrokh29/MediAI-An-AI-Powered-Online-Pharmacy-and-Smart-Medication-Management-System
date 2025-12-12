

import 'package:flutter/material.dart';

class MSectionHeading extends StatelessWidget {
  const MSectionHeading({
    super.key,
    this.textColor,
    this.showActionButton = true,
    required this.title,
    this.buttontitle = 'View all',
    this.onPressed
  
  
  });

  final Color? textColor ;
  final bool showActionButton;
  final String title, buttontitle;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall!.apply(color:textColor),maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        if(showActionButton) TextButton(
          onPressed: onPressed,
          child:  Text(buttontitle,),
        )
      ],
    );
  }
}

