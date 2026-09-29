from app.services.rag import retrieve


def test_trusted_activity_resource_is_retrieved():
    results = retrieve("How much moderate activity should I do each week?")
    assert results
    assert any("CDC" in item.publisher or "WHO" in item.publisher for item in results)
