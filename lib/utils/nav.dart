import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future goToMovie(BuildContext context, int ottId, String movieId) {
  return GoRouter.of(context).push("/movie/$ottId/$movieId");
}
