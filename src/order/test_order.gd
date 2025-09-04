extends GutTest
class_name TestOrder

func test_linear():
    var me = Order.new()
    me.set_type(Order.Type.LINEAR).set_items([0, 1, 2]).set_wrap(false)
    for i in 3:
        assert_eq(me.next(), i, "item %d is %d" % [i, i])
    assert_null(me.next(), "end of items")

func test_ping_pong():
    var me = Order.new()
    me.set_type(Order.Type.PING_PONG).set_items([0, 1, 2]).set_wrap(false)
    var expected = [0, 1, 2, 1, 0, 1]
    for i in expected.size():
        assert_eq(me.next(), expected[i], "item %d is %d" % [i, expected[i]])
