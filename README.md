# Flutter PyTorch 模型测试应用

这是一个演示如何在Flutter应用中使用PyTorch模型的示例项目。

## 模型文件

要使用此应用，您需要将PyTorch模型文件放置在正确的位置：

1. 确保您有一个PyTorch模型文件（`.pt`格式）
2. 将模型文件命名为`model.pt`
3. 将文件放置在项目的`assets/models/`目录中

## 模型获取方法

如果您没有现成的PyTorch模型，可以通过以下方式获取：

1. 使用预训练模型：从PyTorch官方模型库（如torchvision）导出模型
2. 训练自己的模型：使用PyTorch训练模型并导出为`.pt`格式
3. 使用示例模型：从[flutter_pytorch_mobile](https://github.com/fbelderink/flutter_pytorch_mobile)仓库的示例中获取

### 导出PyTorch模型的简单示例

```python
import torch
import torchvision

# 加载预训练的MobileNet v2模型
model = torchvision.models.mobilenet_v2(pretrained=True)
model.eval()

# 导出模型
example_input = torch.rand(1, 3, 224, 224)
traced_script_module = torch.jit.trace(model, example_input)
traced_script_module.save("model.pt")
```

## 在Flutter中使用PyTorch模型

本应用使用`flutter_pytorch`包来加载和运行PyTorch模型。以下是基本用法：

```dart
import 'package:flutter_pytorch/pytorch_mobile.dart';
import 'package:flutter_pytorch/model.dart';
import 'package:flutter_pytorch/enums/dtype.dart';

// 加载模型
Model model = await PyTorchMobile.loadModel('assets/models/model.pt');

// 准备输入数据
final input = [1, 2, 3, 4]; // 示例输入数据
final shape = [1, 2, 2]; // 示例形状

// 运行推理
final prediction = await model.getPrediction(input, shape, DType.float32);
```

## 注意事项

- 确保模型与Flutter应用兼容（使用TorchScript导出）
- 模型大小会影响应用性能和大小
- 复杂模型可能需要更多的处理能力和内存
- 输入数据和形状必须与模型期望的格式匹配

## 参考资料

- [flutter_pytorch_mobile GitHub仓库](https://github.com/fbelderink/flutter_pytorch_mobile)
- [PyTorch Mobile官方文档](https://pytorch.org/mobile/home/)
