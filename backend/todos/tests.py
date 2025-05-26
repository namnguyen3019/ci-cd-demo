import json

from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Todo


class TodoModelTest(TestCase):
    """Test cases for Todo model"""
    
    def setUp(self):
        self.todo = Todo.objects.create(
            title="Test Todo",
            description="Test Description"
        )
    
    def test_todo_creation(self):
        """Test that a todo can be created"""
        self.assertEqual(self.todo.title, "Test Todo")
        self.assertEqual(self.todo.description, "Test Description")
        self.assertFalse(self.todo.completed)
        self.assertIsNotNone(self.todo.created_at)
        self.assertIsNotNone(self.todo.updated_at)
    
    def test_todo_str_representation(self):
        """Test the string representation of todo"""
        self.assertEqual(str(self.todo), "Test Todo")
    
    def test_todo_ordering(self):
        """Test that todos are ordered by creation date (newest first)"""
        todo1 = Todo.objects.create(title="First Todo")
        todo2 = Todo.objects.create(title="Second Todo")
        
        todos = Todo.objects.all()
        self.assertEqual(todos[0], todo2)  # Newest first
        self.assertEqual(todos[1], todo1)


class TodoAPITest(APITestCase):
    """Test cases for Todo API endpoints"""
    
    def setUp(self):
        self.todo = Todo.objects.create(
            title="Test Todo",
            description="Test Description"
        )
        self.list_url = reverse('todo-list')
        self.detail_url = reverse('todo-detail', kwargs={'pk': self.todo.pk})
    
    def test_get_todo_list(self):
        """Test retrieving list of todos"""
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['title'], "Test Todo")
    
    def test_create_todo(self):
        """Test creating a new todo"""
        data = {
            'title': 'New Todo',
            'description': 'New Description'
        }
        response = self.client.post(self.list_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Todo.objects.count(), 2)
        self.assertEqual(response.data['title'], 'New Todo')
    
    def test_create_todo_without_title(self):
        """Test creating a todo without title should fail"""
        data = {
            'description': 'Description without title'
        }
        response = self.client.post(self.list_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_get_todo_detail(self):
        """Test retrieving a specific todo"""
        response = self.client.get(self.detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], "Test Todo")
    
    def test_update_todo(self):
        """Test updating a todo"""
        data = {
            'title': 'Updated Todo',
            'description': 'Updated Description'
        }
        response = self.client.patch(self.detail_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.todo.refresh_from_db()
        self.assertEqual(self.todo.title, 'Updated Todo')
    
    def test_delete_todo(self):
        """Test deleting a todo"""
        response = self.client.delete(self.detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Todo.objects.count(), 0)
    
    def test_toggle_todo_completion(self):
        """Test toggling todo completion status"""
        toggle_url = reverse('todo-toggle-completed', kwargs={'pk': self.todo.pk})
        
        # Initially not completed
        self.assertFalse(self.todo.completed)
        
        # Toggle to completed
        response = self.client.patch(toggle_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.todo.refresh_from_db()
        self.assertTrue(self.todo.completed)
        
        # Toggle back to not completed
        response = self.client.patch(toggle_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.todo.refresh_from_db()
        self.assertFalse(self.todo.completed)
    
    def test_todo_list_ordering(self):
        """Test that todos are returned in correct order (newest first)"""
        Todo.objects.create(title="Second Todo")
        Todo.objects.create(title="Third Todo")
        
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should be ordered by creation date (newest first)
        titles = [todo['title'] for todo in response.data]
        self.assertEqual(titles[0], "Third Todo")
        self.assertEqual(titles[1], "Second Todo")
        self.assertEqual(titles[2], "Test Todo")


class TodoIntegrationTest(APITestCase):
    """Integration tests for Todo functionality"""
    
    def test_complete_todo_workflow(self):
        """Test a complete workflow: create, read, update, delete"""
        # Create a todo
        create_data = {
            'title': 'Integration Test Todo',
            'description': 'Testing complete workflow'
        }
        create_response = self.client.post(reverse('todo-list'), create_data, format='json')
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        todo_id = create_response.data['id']
        
        # Read the todo
        detail_url = reverse('todo-detail', kwargs={'pk': todo_id})
        read_response = self.client.get(detail_url)
        self.assertEqual(read_response.status_code, status.HTTP_200_OK)
        self.assertEqual(read_response.data['title'], 'Integration Test Todo')
        
        # Update the todo
        update_data = {
            'title': 'Updated Integration Test Todo',
            'completed': True
        }
        update_response = self.client.patch(detail_url, update_data, format='json')
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(update_response.data['title'], 'Updated Integration Test Todo')
        self.assertTrue(update_response.data['completed'])
        
        # Delete the todo
        delete_response = self.client.delete(detail_url)
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify deletion
        verify_response = self.client.get(detail_url)
        self.assertEqual(verify_response.status_code, status.HTTP_404_NOT_FOUND)
