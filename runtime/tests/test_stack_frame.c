#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "syli/object.h"
#include "syli/stack_frame.h"
#include "syli/syli.h"
#include "syli/syli_state.h"

#pragma GCC diagnostic ignored "-Wunused-variable"

static obj_ptr make_test_mono_imm_object(size_t word_size)
{
    object_payload_t payload = syli_object_make_mono_payload(word_size);
    object_header_t header   = syli_object_make_header(
        Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, payload);
    return syli_rt_ownership_alloc_object(header, 1, word_size);
}

int main()
{
    printf("\033[1;34m=== Running Stack Frame Tests ===\033[0m\n\n");

    // Initialize syli state for object creation
    syli_state_init();

    // Test 1: Initialize stack
    printf("Test 1: Initialize stack\n");
    StackFrame stack;
    syli_stack_frame_init(&stack, 4);
    assert(stack.frames != NULL);
    assert(stack.top == 0);
    assert(stack.capacity == 4);
    printf("✓ Stack initialized\n\n");

    // Test 2: Push scope with StackFrame1
    printf("Test 2: Push scope with single root\n");
    obj_ptr obj1      = (obj_ptr)0x1000;
    obj_ptr* roots1[] = { &obj1 };
    Frame frame1      = { .root_count = 1, .roots = roots1 };

    int result = syli_stack_frame_push_scope(&stack, &frame1);
    assert(result == 1);
    assert(stack.top == 1);
    assert(stack.frames[0] == &frame1);
    printf("✓ Pushed single root frame\n\n");

    // Test 3: Push scope with StackFrame2
    printf("Test 3: Push scope with two roots\n");
    obj_ptr obj2a     = (obj_ptr)0x2000;
    obj_ptr obj2b     = (obj_ptr)0x2001;
    obj_ptr* roots2[] = { &obj2a, &obj2b };
    Frame frame2      = { .root_count = 2, .roots = roots2 };

    result = syli_stack_frame_push_scope(&stack, &frame2);
    assert(result == 1);
    assert(stack.top == 2);
    assert(stack.frames[1] == &frame2);
    printf("✓ Pushed two root frame\n\n");

    // Test 4: Push scope with StackFrame3
    printf("Test 4: Push scope with three roots\n");
    obj_ptr obj3a     = (obj_ptr)0x3000;
    obj_ptr obj3b     = (obj_ptr)0x3001;
    obj_ptr obj3c     = (obj_ptr)0x3002;
    obj_ptr* roots3[] = { &obj3a, &obj3b, &obj3c };
    Frame frame3      = { .root_count = 3, .roots = roots3 };

    result = syli_stack_frame_push_scope(&stack, &frame3);
    assert(result == 1);
    assert(stack.top == 3);
    assert(stack.frames[2] == &frame3);
    printf("✓ Pushed three root frame\n\n");

    // Test 5: Push dynamic StackFrame
    printf("Test 5: Push dynamic StackFrame\n");
    obj_ptr obj4a = (obj_ptr)0x4000;
    obj_ptr obj4b = (obj_ptr)0x4001;
    obj_ptr obj4c = (obj_ptr)0x4002;
    obj_ptr obj4d = (obj_ptr)0x4003;
    obj_ptr obj4e = (obj_ptr)0x4004;

    // Create array of root pointers
    obj_ptr* roots4[]   = { &obj4a, &obj4b, &obj4c, &obj4d, &obj4e };
    Frame dynamic_frame = { .root_count = 5, .roots = roots4 };

    result = syli_stack_frame_push_scope(&stack, &dynamic_frame);
    assert(result == 1);
    assert(stack.top == 4);
    assert(stack.frames[3] == &dynamic_frame);
    printf("✓ Pushed dynamic StackFrame\n\n");

    // Test 6: Verify stack capacity resize
    printf("Test 6: Verify stack capacity (should still be 4)\n");
    assert(stack.capacity == 4);
    printf("✓ Capacity is %u\n\n", stack.capacity);

    // Test 7: Push one more to trigger resize
    printf("Test 7: Push to trigger resize\n");
    obj_ptr obj5      = (obj_ptr)0x5000;
    obj_ptr* roots5[] = { &obj5 };
    Frame frame5      = { .root_count = 1, .roots = roots5 };

    result = syli_stack_frame_push_scope(&stack, &frame5);
    assert(result == 1);
    assert(stack.top == 5);
    assert(stack.capacity == 8); // Should have doubled
    printf("✓ Pushed 5th scope, capacity resized to %u\n\n", stack.capacity);

    // Test 8: Pop scopes
    printf("Test 8: Pop scopes\n");
    for (uint32_t i = 0; i < 5; i++) {
        result = syli_stack_frame_pop_scope(&stack);
        assert(result == 1);
        assert(stack.top == 4 - i);
    }
    assert(stack.top == 0);
    printf("✓ Popped all 5 scopes\n\n");

    // Test 9: Pop empty stack
    printf("Test 9: Pop empty stack\n");
    result = syli_stack_frame_pop_scope(&stack);
    assert(result == 0); // Should fail
    assert(stack.top == 0);
    printf("✓ Correctly failed to pop empty stack\n\n");

    // Test 10: Create objects and test root tracking
    printf("Test 10: Create objects and test root tracking\n");

    // Create a monotype object with 3 fields
    obj_ptr test_obj1 = make_test_mono_imm_object(3);
    assert(test_obj1 != NULL);
    Object* o1 = syli_object_of_obj_ptr(test_obj1);
    assert(syli_object_length(o1) == 3);

    // Set some values in the object
    uint64_t* data1 = syli_object_data(o1);
    data1[0]        = 42;
    data1[1]        = 123;
    data1[2]        = 999;

    // Create another object
    obj_ptr test_obj2 = make_test_mono_imm_object(2);
    assert(test_obj2 != NULL);
    Object* o2      = syli_object_of_obj_ptr(test_obj2);
    uint64_t* data2 = syli_object_data(o2);
    data2[0]        = 777;
    data2[1]        = 555;

    // Push a frame with these objects as roots
    obj_ptr* root_slots[] = { &test_obj1, &test_obj2 };
    Frame root_frame      = { .root_count = 2, .roots = root_slots };

    result = syli_stack_frame_push_scope(&stack, &root_frame);
    assert(result == 1);
    assert(stack.top == 1);
    printf("✓ Pushed frame with object roots\n");

    // Verify we can access the objects through the roots
    Object* retrieved_obj1 = syli_object_of_obj_ptr(*root_frame.roots[0]);
    Object* retrieved_obj2 = syli_object_of_obj_ptr(*root_frame.roots[1]);

    assert(retrieved_obj1 == o1);
    assert(retrieved_obj2 == o2);
    printf("✓ Retrieved objects from roots match originals\n");

    // Verify the object data is still correct
    uint64_t* retrieved_data1 = syli_object_data(retrieved_obj1);
    uint64_t* retrieved_data2 = syli_object_data(retrieved_obj2);

    assert(retrieved_data1[0] == 42);
    assert(retrieved_data1[1] == 123);
    assert(retrieved_data1[2] == 999);
    assert(retrieved_data2[0] == 777);
    assert(retrieved_data2[1] == 555);
    printf("✓ Object data values are preserved through root tracking\n");

    // Pop the frame
    result = syli_stack_frame_pop_scope(&stack);
    assert(result == 1);
    assert(stack.top == 0);
    printf("✓ Popped frame with object roots\n\n");

    syli_free_ptr(test_obj1);
    syli_free_ptr(test_obj2);

    // Test 11: Destroy
    printf("Test 11: Destroy stack\n");
    syli_stack_frame_destroy(&stack);
    assert(stack.frames == NULL);
    assert(stack.top == 0);
    assert(stack.capacity == 0);
    printf("✓ Stack destroyed\n");

    // Clean up syli state
    syli_state_destroy();
    printf("✓ Syli state cleaned up\n\n");

    printf("\033[1;32m=== All Stack Frame Tests Passed! ===\033[0m\n\n");
    return 0;
}