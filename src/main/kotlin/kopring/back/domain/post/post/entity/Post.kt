package kopring.back.domain.post.post.entity

import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType.IDENTITY
import jakarta.persistence.Id

@Entity
class Post(
    @Id
    @GeneratedValue(strategy = IDENTITY)
    var id: Long? = null,
    var title: String,
    var content: String
)