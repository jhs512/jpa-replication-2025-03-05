package kopring.back.global.initData

import kopring.back.domain.post.post.entity.Post
import kopring.back.domain.post.post.repository.PostRepository
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.ApplicationRunner
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Lazy
import org.springframework.transaction.annotation.Transactional

@Configuration
class BaseInitData(
    private val postRepository: PostRepository
) {
    @Autowired
    @Lazy
    private lateinit var self: BaseInitData

    @Bean
    fun baseApplicationRunner(): ApplicationRunner {
        return ApplicationRunner {
            self.work1()
            self.work2()
            self.work3()
            self.work4()
        }
    }

    @Transactional
    fun work1() {
        if (postRepository.count() > 0) return

        val post1 = Post(title = "title 1", content = "content 2")
        val post2 = Post(title = "title 2", content = "content 2")

        postRepository.save(post1)
        postRepository.save(post2)
    }

    @Transactional(readOnly = true)
    fun work2() {
        postRepository.findAll()
    }

    @Transactional(readOnly = true)
    fun work3() {
        postRepository.findAll()
    }

    @Transactional(readOnly = true)
    fun work4() {
        postRepository.findAll()
    }
}