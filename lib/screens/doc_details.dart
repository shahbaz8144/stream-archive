import 'package:flutter/material.dart';

class DocDetails extends StatefulWidget {
  const DocDetails({super.key});

  @override
  State<DocDetails> createState() => _DocDetailsState();
}

class _DocDetailsState extends State<DocDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('This is doc details page'),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height:400 ,
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Text('doc details here')
                  );
                },
              );
            },
            icon: Icon(Icons.more_vert_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/defaultThumbnail.png"), // Update the path
            fit: BoxFit.cover, // Cover the whole screen
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.star)),
          IconButton(onPressed: () {}, icon: Icon(Icons.push_pin_sharp)),
          IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
          IconButton(onPressed: () {}, icon: Icon(Icons.save_alt)),
          IconButton(  onPressed: () {
    showModalBottomSheet(
    context: context,
    builder: (context) {
    return Container(
    height:400 ,
    width: double.infinity,
    padding: EdgeInsets.all(16),
    child: Text('doc details here')
    );
    },
    );
    }, icon: Icon(Icons.info)),
        ],
      ),
    );
  }
}
