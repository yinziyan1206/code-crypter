```python
    from crypter import generator
    # obscure a script
    generator.transform('test.py', 'test_transformed.py')
    # obscure a module
    generator.transform_all('demo/')
```