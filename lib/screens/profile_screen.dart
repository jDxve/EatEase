import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 174, 20, 9),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Edit logic here
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-mail',
                          value: 'johndavebanas815@gmail.com',
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: '09104979045',
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: 'Cabasan, Bacacay, Albay',
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          icon: Icons.lock_outline,
                          label: 'Password',
                          value: '****************',
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Order History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 174, 20, 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 111, 110, 110),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
