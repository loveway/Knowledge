# iOS 中 UITableView 实现多选的一种优雅的方案

在我们平时开发中，经常会遇到有个列表可以多选，然后选中后回到上一页，并把选中的数据带过去，或者把选中的结果提交，如下图

经常我们的做法是在数据源中做操作，比如将一个 model 添加一个 isSelected 属性，选中就置为 YES，然后刷新，最后提交时候遍历数据源，找到 isSelected 为 YES 的再做处理，如下

```objc

...

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMTestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MMTestTableViewCell" forIndexPath:indexPath];
    MMModel *model = _dataArray[indexPath.row];
    cell.statusLabel.text = model.title;
    if (model.isSelected) {
        cell.statusLabel.textColor = [UIColor redColor];
    } else {
        cell.statusLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMModel *model = _dataArray[indexPath.row];
    model.isSelected = !model.isSelected;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}
```

现在有种比较优雅的方式，不用去改 model，直利用 UITableView 的 allowsMultipleSelection 属性，就可以简单的去操作
### 1. 开启允许多选
```objc
// 开启允许多选，默认为 NO
self.tableView.allowsMultipleSelection = YES;
```
### 2. 分别在下面三个方法中作相应操作

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MMTestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MMTestTableViewCell" forIndexPath:indexPath];
    cell.statusLabel.text = _dataArray[indexPath.row][@"title"];
    if ([[tableView indexPathsForSelectedRows] containsObject:indexPath]) {
        cell.statusLabel.textColor = [UIColor redColor];
    } else {
        cell.statusLabel.textColor = [UIColor blackColor];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMTestTableViewCell *cell = (MMTestTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.statusLabel.textColor = [UIColor redColor];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMTestTableViewCell *cell = (MMTestTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.statusLabel.textColor = [UIColor blackColor];
}
```
### 3. 提取所选数据

```objc
NSString *res = @"";
for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
    res = [res stringByAppendingString:@" "];
    res = [res stringByAppendingString:_dataArray[indexPath.row][@"title"]];
}
UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选中的title" message:res preferredStyle:UIAlertControllerStyleAlert];
UIAlertAction *action = [UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { 
}];
[alert addAction:action];
[self presentViewController:alert animated:YES completion:nil];
```

最后就可以得图示效果，这种方法简单方便，并且对 model 无入侵，比较优雅！