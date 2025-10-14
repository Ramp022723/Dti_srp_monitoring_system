import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProductFoldersPage extends StatefulWidget {
  const ProductFoldersPage({super.key});

  @override
  State<ProductFoldersPage> createState() => _ProductFoldersPageState();
}

class _ProductFoldersPageState extends State<ProductFoldersPage> {
  bool _isLoading = true;
  List<dynamic> _folders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Using the product folder management API
      final result = await AuthService.getProductFolders();
      
      if (result['status'] == 'success') {
        setState(() {
          // The API returns {status, message, data: {success, message, data: {folders}}}
          final apiData = result['data'] ?? {};
          _folders = apiData['data']?['folders'] ?? apiData['folders'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load folders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading folders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            'Product Folders',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadFolders,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildFoldersContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateFolderDialog,
          backgroundColor: const Color(0xFF3B82F6),
          icon: const Icon(Icons.create_new_folder, color: Colors.white),
          label: const Text(
            'New Folder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Folders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFolders,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersContent() {
    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Folders Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first product folder to organize products',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateFolderDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics Row
        _buildFolderStatistics(),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search folders...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                // TODO: Implement search functionality
              });
            },
          ),
        ),
        
        // Folders List with Tree View Toggle
        Expanded(
          child: Row(
            children: [
              // Tree View Panel
              Container(
                width: 200,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: _buildFolderTreeView(),
              ),
              
              // Main Folders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    return _buildFolderCard(folder);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderStatistics() {
    final totalFolders = _folders.length;
    final totalProducts = _folders.fold<int>(0, (sum, folder) => sum + ((folder['product_count'] ?? 0) as int));
    final hierarchicalFolders = _folders.where((folder) => folder['is_hierarchical'] == true).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Folders',
              totalFolders.toString(),
              Icons.folder,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Total Products',
              totalProducts.toString(),
              Icons.inventory,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Hierarchical',
              hierarchicalFolders.toString(),
              Icons.account_tree,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTreeView() {
    // Group folders by parent
    final Map<int?, List<dynamic>> folderGroups = {};
    for (var folder in _folders) {
      final parentId = folder['parent_id'];
      folderGroups.putIfAbsent(parentId, () => []).add(folder);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Folder Tree',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(),
        ..._buildTreeItems(folderGroups[null] ?? [], folderGroups, 0),
      ],
    );
  }

  List<Widget> _buildTreeItems(List<dynamic> folders, Map<int?, List<dynamic>> folderGroups, int level) {
    return folders.map((folder) {
      final children = folderGroups[folder['id']] ?? [];
      final hasChildren = children.isNotEmpty;
      
      return Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(left: 8 + (level * 16)),
            leading: Icon(
              hasChildren ? Icons.folder : Icons.folder_outlined,
              color: Colors.blue,
              size: 20,
            ),
            title: Text(
              folder['folder_name'] ?? 'Unnamed',
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              '${folder['product_count'] ?? 0} products',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              // TODO: Implement folder selection
            },
          ),
          if (hasChildren)
            ..._buildTreeItems(children, folderGroups, level + 1),
        ],
      );
    }).toList();
  }

  Widget _buildFolderCard(dynamic folder) {
    final folderName = folder['folder_name'] ?? 'Unnamed Folder';
    final productCount = folder['product_count'] ?? 0;
    final folderId = folder['folder_id'] ?? folder['id'];
    final isHierarchical = folder['is_hierarchical'] ?? false;
    final parentFolder = folder['parent_folder'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to folder details or products
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening folder: $folderName')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Folder Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHierarchical ? Icons.folder_special : Icons.folder,
                  color: Colors.blue[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Folder Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folderName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$productCount products',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (parentFolder != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Parent: $parentFolder',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditFolderDialog(folder);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(folderId, folderName);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'Enter folder name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _createFolder(nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(dynamic folder) {
    final nameController = TextEditingController(text: folder['folder_name']);
    final folderId = folder['folder_id'] ?? folder['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _updateFolder(folderId, nameController.text);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic folderId, String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "$folderName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFolder(folderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(String folderName) async {
    try {
      final result = await AuthService.createFolder(
        name: folderName,
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created successfully'), backgroundColor: Colors.green),
        );
        _loadFolders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateFolder(dynamic folderId, String folderName) async {
    try {
      final result = await AuthService.updateFolder(
        folderId: int.parse(folderId.toString()),
        name: folderName,
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder updated successfully'), backgroundColor: Colors.green),
        );
        _loadFolders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteFolder(dynamic folderId) async {
    try {
      final result = await AuthService.deleteFolder(
        folderId: int.parse(folderId.toString()),
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted successfully'), backgroundColor: Colors.green),
        );
        _loadFolders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

