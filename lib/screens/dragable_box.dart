import 'package:flutter/material.dart';

class DragableBox extends StatefulWidget {

  final String documentUrl;
  const DragableBox({super.key, required  this.documentUrl});

  @override
  State<DragableBox> createState() => _DragableBoxState();
}

class _DragableBoxState extends State<DragableBox> {

  Offset position = Offset(100, 100); // initial position of box

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text("Template"),),
     body: Stack(
       children: [
         // Top bar showing coordinates
         Positioned(
           top: 40,
           left: 20,
           child: Row(
             children: [
               Container(
                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                 decoration: BoxDecoration(
                   color: Colors.black87,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   "X: ${position.dx.toStringAsFixed(1)}   Y: ${position.dy.toStringAsFixed(1)}",
                   style: TextStyle(color: Colors.white, fontSize: 16),
                 ),
               ),
               SizedBox(width: 10.0,),
               OutlinedButton(
                 onPressed: () {
                   // Add your update position logic here
                 },
                 style: OutlinedButton.styleFrom(
                   backgroundColor: Colors.blue, // Blue background
                   minimumSize: Size(80, 40), // Width x Height
                   side: BorderSide(color: Colors.blue), // Optional: blue border
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(4), // Square-ish corners
                   ),
                 ),
                 child: Text(
                   'Update Position',
                   style: TextStyle(color: Colors.white), // White text
                 ),
               )


             ],
           ),
         ),

         // Draggable box
     Center(
       child: Container(
         width: 360,
         height: 360,
         decoration: BoxDecoration(
           border: Border.all(color: Colors.grey, width: 3),
           borderRadius: BorderRadius.circular(10),
         ),
         child: LayoutBuilder(
           builder: (context, constraints) {
             double boxSize = 100;
             double maxX = constraints.maxWidth - boxSize;
             double maxY = constraints.maxHeight - boxSize;

             return Stack(
               children: [
                 // Draggable box inside frame
                 Positioned(
                   left: position.dx,
                   top: position.dy,
                   child: Draggable(

                     feedback: Container(
                         width: 120,
                         height: 120,
                         decoration: BoxDecoration(
                           // color: Colors.blue,
                           borderRadius: BorderRadius.circular(12),
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                         ),
                         child: Image.network(widget.documentUrl)

                     ),
                     childWhenDragging: Container(),
                     child: Container(
                         width: 120,
                         height: 120,
                         decoration: BoxDecoration(
                           // color: Colors.blue,
                           borderRadius: BorderRadius.circular(12),
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                         ),
                         child: Image.network(widget.documentUrl)

                     ),
                     onDraggableCanceled: (velocity, offset) {
                       // Convert global offset to local inside the frame
                       RenderBox box = context.findRenderObject() as RenderBox;
                       Offset localOffset = box.globalToLocal(offset);

                       // Clamp position to keep box inside container
                       double clampedX = localOffset.dx.clamp(0.0, maxX);
                       double clampedY = localOffset.dy.clamp(0.0, maxY);

                       setState(() {
                         position = Offset(clampedX, clampedY);
                       });
                     },
                   ),
                 ),
               ],
             );
           },
         ),
       ),
     )
       ],
     ),
   );
  }

}

// Widget _buildDraggableBox(Offset pos) {
//   return ;
// }

