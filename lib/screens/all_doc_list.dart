import 'package:flutter/material.dart';

class AllDocList extends StatefulWidget {
  const AllDocList({super.key});

  @override
  State<AllDocList> createState() => _AllDocListState();
}

class _AllDocListState extends State<AllDocList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('This is first page'),),
      body: Text('This is Stream archive'),
    );
  }
}
