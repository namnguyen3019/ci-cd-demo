import { CreateTodoRequest, Todo, UpdateTodoRequest } from '@/types/todo';
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const todoApi = {
  // Get all todos
  getTodos: async (): Promise<Todo[]> => {
    const response = await api.get('/api/todos/');
    return response.data;
  },

  // Create a new todo
  createTodo: async (todo: CreateTodoRequest): Promise<Todo> => {
    const response = await api.post('/api/todos/', todo);
    return response.data;
  },

  // Update a todo
  updateTodo: async (id: number, todo: UpdateTodoRequest): Promise<Todo> => {
    const response = await api.patch(`/api/todos/${id}/`, todo);
    return response.data;
  },

  // Delete a todo
  deleteTodo: async (id: number): Promise<void> => {
    await api.delete(`/api/todos/${id}/`);
  },

  // Toggle todo completion
  toggleTodo: async (id: number): Promise<Todo> => {
    const response = await api.patch(`/api/todos/${id}/toggle_completed/`);
    return response.data;
  },
}; 