import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SessionDashboardScreen extends StatefulWidget {
  final int sessionId;

  const SessionDashboardScreen({super.key, required this.sessionId});

  @override
  _SessionDashboardScreenState createState() => _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends State<SessionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Session Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
              Colors.indigo.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getSessionDashboard(widget.sessionId),
            builder: (context, snapshot) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(context, snapshot),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          backgroundColor: Colors.white24,
          strokeWidth: 3,
        ),
      );
    }
    if (snapshot.hasError) {
      return Center(
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return Center(
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'No data found.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final padding = constraints.maxWidth * 0.04; // 4% of screen width
        final fontScale = isSmallScreen ? 0.9 : 1.0;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: padding / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Session Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    fontSize: 24 * fontScale,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: padding / 2),
                Text(
                  'Key Metrics & Feedback Insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: padding),
                _buildMetricsGrid(snapshot.data!, constraints),
                SizedBox(height: padding),
                _buildImpactSummaryCard(snapshot.data!),
                SizedBox(height: padding),
                _buildSuggestionsCard(snapshot.data!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    Map<String, dynamic> data,
    BoxConstraints constraints,
  ) {
    final isSmallScreen = constraints.maxWidth < 400;
    final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
    final childAspectRatio = isSmallScreen ? 1.6 : 1.8;

    return _buildGlassCard(
      child: Padding(
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricTile(
              icon: Icons.person_add,
              title: 'Registered',
              value: '${data['registered_count'] ?? 0}',
              color: Colors.blue.shade600,
              fontScale: isSmallScreen ? 0.9 : 1.0,
            ),
            _buildMetricTile(
              icon: Icons.check_circle,
              title: 'Attended',
              value: '${data['attended_count'] ?? 0}',
              color: Colors.green.shade600,
              fontScale: isSmallScreen ? 0.9 : 1.0,
            ),
            _buildMetricTile(
              icon: Icons.pie_chart,
              title: 'Attendance %',
              value:
                  '${(data['attendance_percentage'] ?? 0.0).toStringAsFixed(1)}%',
              color: Colors.purple.shade600,
              progress: (data['attendance_percentage'] ?? 0.0) / 100,
              fontScale: isSmallScreen ? 0.9 : 1.0,
            ),
            _buildMetricTile(
              icon: Icons.star,
              title: 'Avg Rating',
              value: data['average_rating']?.toString() ?? 'N/A',
              color: Colors.orange.shade600,
              rating: data['average_rating'],
              fontScale: isSmallScreen ? 0.9 : 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? progress,
    double? rating,
    required double fontScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20 * fontScale),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      height: 20 * fontScale,
                      width: 20 * fontScale,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange.shade600,
                          size: 14 * fontScale,
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpactSummaryCard(Map<String, dynamic> data) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Impact Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['impact_summary'] ?? 'No feedback yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(Map<String, dynamic> data) {
    final suggestions = (data['improvement_suggestions'] as List?) ?? [];
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Suggestions for Improvement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            suggestions.isEmpty
                ? Text(
                  'No suggestions provided.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 8,
                        thickness: 0.5,
                        color: Colors.white.withOpacity(0.2),
                      ),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            color: Colors.yellow.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestions[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
