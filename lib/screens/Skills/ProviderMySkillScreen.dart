import 'package:first_flutter/baseControllers/APis.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/provider_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/provider_job_offering_card.dart';
import 'MySkillProvider.dart';

class ProviderMySkillScreen extends StatefulWidget {
  const ProviderMySkillScreen({super.key});

  @override
  State<ProviderMySkillScreen> createState() => _ProviderMySkillScreenState();
}

class _ProviderMySkillScreenState extends State<ProviderMySkillScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch skills when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MySkillProvider>(context, listen: false).fetchSkills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProviderOnlyTitleAppbar(title: "Job Offerings"),
      backgroundColor: ColorConstant.scaffoldGray,
      body: Consumer<MySkillProvider>(
        builder: (context, skillProvider, child) {
          if (skillProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (skillProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    skillProvider.errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => skillProvider.fetchSkills(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (skillProvider.skills.isEmpty) {
            return Center(
              child: Text(
                'No job offerings found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => skillProvider.fetchSkills(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: skillProvider.skills.length,
              itemBuilder: (context, index) {
                final skill = skillProvider.skills[index];
                return ProviderJobOfferingCard(
                  subCat: skill.skillName ?? 'Unknown Skill',
                  verified: skill.status == 'approved',
                  serviceName: skill.serviceName,
                  experience: skill.experience,
                  status: skill.status,
                  isChecked: skill.isChecked ?? false,
                  onToggle: (value) async {
                    // Call the API to update skill status
                    final success = await skillProvider.updateSkillCheckedStatus(
                      skill.id!,
                      value,
                    );

                    if (!success && mounted) {
                      // Show error message if update failed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              skillProvider.errorMessage ??
                                  'Failed to update skill status'
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      // Refresh to get the correct state from server
                      await skillProvider.fetchSkills();
                    } else if (success && mounted) {
                      // Optional: Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Skill status updated successfully'),
                          backgroundColor: ColorConstant.moyoGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}