import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String title = '';
  String description = '';

  //List<dynamic> dataList = [];
  List<Map<String, dynamic>> dataList = [];
  bool _isloading =true;

  Future<void> retrieveData() async {
    final String url = 'http://192.168.211.221:9090/retrieve_data';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        dataList = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print('Error retrieving data: ${response.body}');
    }
  }

  Future<void> _refreshRecord() async {
    final data = await retrieveData();
    setState(() {
     // dataList = data;
      _isloading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    //retrieveData();
  }

  Future<void> insertRecord() async {
    final apiUrl = Uri.parse("http://192.168.211.221:9090/insert_record");
    final title = titleController.text;
    final description = descriptionController.text;

    try {
      final response = await http.get(
        Uri.parse(
            '$apiUrl?title=${titleController.text}&description=${descriptionController.text}'),
      );

      if (response.statusCode == 200) {
        print("Record inserted successfully!");
        // Refresh the list view after insertion
        //retrieveData();
      } else {
        throw Exception('Failed to insert record');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> deleteRecord(int id) async {
    final int recordIdToDelete = id; // Replace with the ID of the record you want to delete

    final response = await http.get(
      Uri.parse('http://192.168.211.221:9090/delete_record/$recordIdToDelete'), // Replace with your server's URL
    );

    if (response.statusCode == 200) {
      print('Record deleted successfully');
      _refreshRecord();
    } else if (response.statusCode == 404) {
      print('Record not found');
    } else {
      print('Error: ${response.statusCode}');
    }
  }
  Future<void> updateRecord(int id) async {

    final int recordIdToDelete = id;
    final String title = titleController.text;
    final String description = descriptionController.text;

    if (id == 0 || title.isEmpty || description.isEmpty) {
      // Validation: Check if fields are not empty and ID is valid.
      print('Please enter valid data.');
      return;
    }

    final Uri url = Uri.parse('http://192.168.211.221:9090/update_record/$recordIdToDelete');
    final response = await http.get(
      Uri.parse(
          '$url?title=${titleController.text}&description=${descriptionController.text}'),
    );

    if (response.statusCode == 200) {
      print('Record updated successfully');
      _refreshRecord();
    } else if (response.statusCode == 404) {
      print('Record not found');
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  void _showForm(int ? id) async {
    if (id != null) {
      final existingjournal =
      dataList.firstWhere((element) => element['id'] == id);
      titleController.text = existingjournal['title'];
      descriptionController.text = existingjournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_)=>Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom +120,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'title'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'description'),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  if(id==null){
                    await insertRecord();
                  }
                  if(id !=null){
                    await updateRecord(id);
                  }
                  titleController.text='';
                  descriptionController.text = '';
                  Navigator.of(context).pop();
                },
                child: Text(id==null ? 'Create new' : 'Update'),
              )
            ],
          ),
        )
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: insertRecord,
                child: Text('Insert Record'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: retrieveData,
                child: Text('Retrieve Data'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    final item = dataList[index];
                    final id = item['id'];
                    final title = item['title'];
                    final description = item['description'];
                    return ListTile(
                      title: Text(
                        title.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      subtitle: Text(
                          description.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(item['id']),


                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: (){
                                deleteRecord(id);
                              },

                            )
                          ],
                        ),
                      ),
                      // You can customize the appearance of each list item as needed.
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
