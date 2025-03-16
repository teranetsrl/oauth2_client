import 'package:flutter/material.dart';
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'oauth2_client example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'oauth2_client example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _body = 'Please authenticate.';

  Future<void> _authenticate() async {
    var hlp = OAuth2Helper(
      GoogleOAuth2Client(
          redirectUri: 'com.teranet.app://oauth2redirect',
          customUriScheme: 'com.teranet.app'),
      grantType: OAuth2Helper.authorizationCode,
      clientId: 'XXX-XXX-XXX',
      clientSecret: 'XXX-XXX-XXX',
      scopes: ['https://www.googleapis.com/auth/drive.readonly'],
    );

    var resp = await hlp.get('https://www.googleapis.com/drive/v3/files');
    setState(() {
      _body = resp.body;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _body,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _authenticate,
        tooltip: 'Authenticate',
        child: const Icon(Icons.add),
      ),
    );
  }
}
