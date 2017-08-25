pragma solidity 0.4.15;

contract BlogManager {
    struct Post {
        string title;
        uint id; // index of the post in the posts arr
        bytes32 bzzHash;
        uint timePublished;
    }
    
    struct Comment {
        address commenter;
        uint amount;
        string text;
    }
    
    event LogPostPublished(uint id);
    event LogPostUnpublished(uint id);
    event LogDonationReceived(uint id);
    event LogWithdrawn(uint amount);
    event LogKilled();
    
    address owner;
    mapping(bytes32 => Post) public postRegistry;
    bytes32[] public posts; // bzz hashes of the posts
    mapping(uint => Comment[]) public comments;
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    // constructor
    function BlogManager() {
        owner = msg.sender;
    }
    
    // publish allows owner to publish a post to post registry
    // returns the id of the published post
    function publish(bytes32 bzzHash, string title) ownerOnly() 
        public returns (bool, uint) 
    {
        // the post must be new
        require(postRegistry[bzzHash].timePublished == 0);
        uint id = posts.length;
        Post memory newPost = Post({
            title: title,
            id: id,
            bzzHash: bzzHash,
            timePublished: block.number
        });
        // add to registry and posts arr
        postRegistry[bzzHash] = newPost;
        posts.length = posts.push(bzzHash);
        LogPostPublished(id);
        return (true, id);
    }
    
    // unpublish removes a post from post registry
    // only zeros out the metadatas
    // obviously it cannot remove the post from Swarm
    function unpublish(uint id) ownerOnly() public returns (bool) {
        require(posts[id] != 0);
        bytes32 bzzHash = posts[id];
        // delete the post from registry and posts arr
        delete postRegistry[bzzHash];
        delete posts[id];
        LogPostUnpublished(id);
        return true;
    }
    
    // comment allows someone to comment on a post
    // payable, because they can optionally donate and support the blog owner
    function comment(uint id, string text) payable returns (bool) {
        require(posts[id] != 0); // post must exist
        comments[id].length = comments[id].push(Comment({
            commenter: msg.sender,
            amount: msg.value,
            text: text
        }));
        return (true);
    }
    
    // withdraw allows owner to withdraw donations from contract
    function withdraw() ownerOnly() returns (bool) {
        uint amount = this.balance;
        owner.transfer(this.balance);
        LogWithdrawn(amount);
        return true;
    }
    
    // kill shuts down the blog
    function kill() ownerOnly() returns (bool) {
        selfdestruct(owner);
        LogKilled();
        return true;
    }
    
    // getPostCount returns the total number of posts created
    // note that it also counts unpublished posts
    function getPostCount() constant returns (uint) {
        return posts.length;
    }
    
    // getCommentCount returns the total number of comments of a post
    function getCommentCount(uint id) constant returns (uint) {
        return comments[id].length;
    }
}
