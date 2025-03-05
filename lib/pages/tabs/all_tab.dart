import 'package:flutter/material.dart';

class AllTabPage extends StatelessWidget {
  const AllTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildHotSection(),
        _buildProductList(),
      ],
    );
  }

  Widget _buildHotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '热榜',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 热榜内容列表
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: Center(child: Text('图片${index + 1}')),
                ),
              ),
              title: Text('热门内容 ${index + 1}'),
              subtitle: Wrap(
                spacing: 8,
                children: const [
                  Chip(label: Text('语音交互')),
                  Chip(label: Text('多剧情')),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[300],
                  child: Center(child: Text('商品图片${index + 1}')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('商品标题 ${index + 1}'),
                    const SizedBox(height: 4),
                    Text('¥${488 + index * 100}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 