import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_questions_service.dart';

class ProductQuestionsScreen extends StatefulWidget {
  final String storeId;

  const ProductQuestionsScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<ProductQuestionsScreen> createState() => _ProductQuestionsScreenState();
}

class _ProductQuestionsScreenState extends State<ProductQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductQuestionsService _questionsService = ProductQuestionsService();
  
  int _unansweredCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    print('🚀 [Questions Screen] Initialized with storeId: ${widget.storeId}');
    _tabController = TabController(length: 3, vsync: this);
    _loadUnansweredCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnansweredCount() async {
    final count = await _questionsService.getUnansweredCount(
      storeId: widget.storeId,
    );
    if (mounted) {
      setState(() {
        _unansweredCount = count;
        _isLoadingCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product Questions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFb71000),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                const Tab(text: 'Unanswered'),
                const Tab(text: 'Answered'),
                const Tab(text: 'All'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(answered: false),
                _buildQuestionsTab(answered: true),
                _buildQuestionsTab(answered: null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab({required bool? answered}) {
    print('📱 [Questions Tab] Building tab with answered filter: $answered');
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _questionsService.getAllStoreQuestions(
        storeId: widget.storeId,
        answered: answered,
      ),
      builder: (context, snapshot) {
        print('📱 [Questions Tab] Snapshot state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          print('❌ [Questions Tab] Error: ${snapshot.error}');
        }
        
        if (snapshot.hasData) {
          print('📱 [Questions Tab] Data received: ${snapshot.data!.length} questions');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(answered);
        }

        final questions = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            await _loadUnansweredCount();
            setState(() {});
          },
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _buildQuestionCard(question);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool? answered) {
    String message;
    IconData icon;

    if (answered == false) {
      message = 'No unanswered questions';
      icon = Iconsax.tick_circle;
    } else if (answered == true) {
      message = 'No answered questions yet';
      icon = Iconsax.message_question;
    } else {
      message = 'No questions yet';
      icon = Iconsax.message_question;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final createdAt = question['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null
        ? _questionsService.getTimeAgo(createdAt)
        : '';
    final hasAnswer = question['answer'] != null &&
        (question['answer'] as String).isNotEmpty;
    final productName = question['productName'] ?? 'Unknown Product';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              productName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Iconsax.message_question,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['question'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${question['userName']} • $timeAgo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Answer or Answer button
          if (hasAnswer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.message_text,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['answer'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your answer',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAnswerDialog(question, isEdit: true),
                  icon: const Icon(Iconsax.edit, size: 16),
                  label: Text(
                    'Edit Answer',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAnswerDialog(question),
                icon: const Icon(Iconsax.message_text, size: 18),
                label: Text(
                  'Answer Question',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFb71000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> question, {bool isEdit = false}) {
    final answerController = TextEditingController(
      text: isEdit ? (question['answer'] ?? '') : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit ? 'Edit Answer' : 'Answer Question',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the question
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question['question'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFfb2a0a)),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (answerController.text.trim().isEmpty) return;

              try {
                if (isEdit) {
                  await _questionsService.updateAnswer(
                    storeId: widget.storeId,
                    productId: question['productId'],
                    questionId: question['id'],
                    answer: answerController.text.trim(),
                  );
                } else {
                  await _questionsService.answerQuestion(
                    storeId: widget.storeId,
                    productId: question['productId'],
                    questionId: question['id'],
                    answer: answerController.text.trim(),
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadUnansweredCount();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Answer updated' : 'Answer submitted',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to submit answer',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFb71000),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isEdit ? 'Update' : 'Submit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
