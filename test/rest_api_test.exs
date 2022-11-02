defmodule RestApiTest.Router do
  use ExUnit.Case
  use Plug.Test

  import Plug.BasicAuth

  @opts RestApi.Router.init([])

  test "Should return ok" do
    conn = conn(:get, "/")
    conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
    conn = RestApi.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "OK"
  end

  test "Should return Not Found" do
    conn = conn(:get, "/url_not_exists")
    conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
    conn = RestApi.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "Not Found"
  end

  describe "Posts" do
    setup do
      on_exit fn ->
        Mongo.show_collections(:mongo)
        |> Enum.each(fn col -> Mongo.delete_many!(:mongo, col, %{}) end)
      end
    end

    test "POST /post should return ok" do
      assert Mongo.find(:mongo, "Posts", %{}) |> Enum.count == 0

      conn = conn(:post, "/post", %{name: "Post 1", content: "Content of post"})
      conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
      conn = RestApi.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert %{
        "id" => _,
        "content" => "Content of post",
        "name" => "Post 1"
      } = Jason.decode!(conn.resp_body)
      assert Mongo.find(:mongo, "Posts", %{}) |> Enum.count == 1
    end

    def createPosts() do
      result = Mongo.insert_many!(:mongo, "Posts", [
        %{name: "Post 1", content: "Content 1"},
        %{name: "Post 2", content: "Content 2"}
      ])

      result.inserted_ids |> Enum.map(fn id -> BSON.ObjectId.encode!(id) end)
    end

    test "GET /posts shoould fetch all the posts" do
      createPosts()

      conn = conn(:get, "/posts")
      conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
      conn = RestApi.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200

      resp = Jason.decode!(conn.resp_body)

      assert Enum.count(resp) == 2
      assert %{
        "id" => _,
        "content" => "Content 1",
        "name" => "Post 1"
      } = Enum.at(resp, 0)
      assert %{
        "id" => _,
        "content" => "Content 2",
        "name" => "Post 2"
      } = Enum.at(resp, 1)
    end

    test "GET /post/:id should fetch a single post" do
      [id | _] = createPosts()

      conn = conn(:get, "/post/#{id}")
      conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
      conn = RestApi.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert %{
        "id" => _,
        "content" => "Content 1",
        "name" => "Post 1"
      } = Jason.decode!(conn.resp_body)
    end

    test "PUT /post/:id should update a post" do
      [id | _] = createPosts()

      conn = conn(:put, "/post/#{id}", %{content: "Content 3"})
      conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
      conn = RestApi.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert %{
        "id" => _,
        "content" => "Content 3",
        "name" => "Post 1"
      } = Jason.decode!(conn.resp_body)
    end

    test "DELETE /post/:id should delete a post" do
      [id | _] = createPosts()

      assert Mongo.find(:mongo, "Posts", %{}) |> Enum.count == 2

      conn = conn(:delete, "/post/#{id}", %{content: "Content 3"})
      conn = put_req_header(conn, "authorization", encode_basic_auth("3vZqMxmT", "JAU7fe5O"))
      conn = RestApi.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert Mongo.find(:mongo, "Posts", %{}) |> Enum.count == 1
    end
  end
end
