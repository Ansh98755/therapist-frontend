import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:therapist_app/core/shared_pref.dart';
import 'package:therapist_app/utils/assets_constants/assets_constants.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
import 'package:therapist_app/utils/string_constants/string_constants.dart';
import 'package:therapist_app/utils/text_style_constants/text_style_constants.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  bool isPostAnony = false;
  bool commentsEnabled = true;
  bool _isPosting = false;

  Future<void> postToServer() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    final titleWords = title
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final bodyWords = body
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    if (title.isEmpty || body.isEmpty) {
      _showFlushBar(
        context,
        message: "Title and Body are required",
        color: Colors.red,
      );
      return;
    }

    if (titleWords > 20) {
      _showFlushBar(
        context,
        message: "Title cannot be more than 20 words",
        color: Colors.red,
      );
      return;
    }
    if (title.length > 100) {
      _showFlushBar(
        context,
        message: "Title cannot be more than 100 characters",
        color: Colors.red,
      );
      return;
    }

    if (bodyWords > 1000) {
      _showFlushBar(
        context,
        message: "Body cannot be more than 1000 words",
        color: Colors.red,
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final uri = Uri.parse('https://niti.nexuserp.co.in/api/v1/post');
      final Ss = SharedPrefService();
      final token = await Ss.getToken();

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          if (isPostAnony) 'anonymous': true,
          if (!commentsEnabled) 'commentsEnabled': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _showFlushBar(
          context,
          message: responseData['message'] ?? "Post added successfully",
          color: Colors.green,
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showFlushBar(
          context,
          message: "Failed: ${response.body}",
          color: Colors.red,
        );
      }
    } catch (e) {
      _showFlushBar(context, message: "Error: $e", color: Colors.red);
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: ColorConstants.whiteColor2,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: ColorConstants.whiteColor2,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor2,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          surfaceTintColor: ColorConstants.transparentColor,
          shadowColor: Colors.grey.withOpacity(0.3),
          backgroundColor: ColorConstants.whiteColor,
          elevation: 0,
          // centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Image.asset(
                AssetsConstants.postCloseBtn,
                width: 24,
                height: 24,
              ),
              constraints: const BoxConstraints(maxWidth: 48, maxHeight: 48),
            ),
          ),
          title: Text(
            StringConstants.newPost,
            style: TextStyleConstants.inter20W600.copyWith(
              color: ColorConstants.blackColor,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorConstants.primaryBrownColor,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme: const InputDecorationTheme(
                                      border: InputBorder.none,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter title (max 20 words)',
                                      hintStyle: TextStyleConstants.inter14W400
                                          .copyWith(
                                            color: ColorConstants.hintColor,
                                          ),
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyleConstants.inter16W500
                                        .copyWith(
                                          color: ColorConstants.blackColor,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              constraints: const BoxConstraints(minHeight: 144),
                              decoration: BoxDecoration(
                                color: ColorConstants.whiteColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ColorConstants.primaryBrownColor,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: const InputDecorationTheme(
                                    border: InputBorder.none,
                                  ),
                                ),
                                child: TextField(
                                  controller: _bodyController,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration.collapsed(
                                    hintText: StringConstants.postTextHint,
                                    hintStyle: TextStyleConstants.inter14W400
                                        .copyWith(
                                          color: ColorConstants.hintColor,
                                        ),
                                    border: InputBorder.none
                                  ),
                                  style: TextStyleConstants.inter16W500.copyWith(
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  StringConstants.postAnony,
                                  style: TextStyleConstants.roboto16W400Dark
                                      .copyWith(height: 24 / 16),
                                ),
                                Switch(
                                  value: isPostAnony,
                                  onChanged: (val) =>
                                      setState(() => isPostAnony = val),
                                  activeColor:
                                      ColorConstants.primaryOrangeColor,
                                  trackColor: MaterialStateProperty.all(
                                    ColorConstants.primaryBrownColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Enable Comments",
                                  style: TextStyle(fontSize: 16),
                                ),
                                Switch(
                                  value: commentsEnabled,
                                  onChanged: (val) =>
                                      setState(() => commentsEnabled = val),
                                  activeColor:
                                      ColorConstants.primaryOrangeColor,
                                  trackColor: MaterialStateProperty.all(
                                    ColorConstants.primaryBrownColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isPosting ? null : postToServer,
                                child: Ink(
                                  width: maxWidth - 32,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _isPosting
                                        ? Colors.grey
                                        : ColorConstants.primaryBrownColor,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: _isPosting
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            StringConstants.postButtonText,
                                            style: TextStyleConstants
                                                .inter16W600
                                                .copyWith(
                                                  color:
                                                      ColorConstants.whiteColor,
                                                ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFlushBar(
    BuildContext context, {
    required String message,
    required Color color,
  }) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 1),
      backgroundColor: color,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        color == Colors.green ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }
}
