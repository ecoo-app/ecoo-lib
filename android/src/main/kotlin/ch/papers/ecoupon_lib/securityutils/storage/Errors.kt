package ch.papers.ecoupon_lib.securityutils.storage
import java.lang.Exception

object Errors {
    const val ITEM_CORRUPTED = "Item corrupted"
    const val DIGEST_NOT_MATCHING = "Digest did not match, wrong secret"
    const val CANNOT_DELETE_FILE = "Could not delete file"
    const val AUTHENTICATION_REQUIRED = "User authentication needed"
    const val USER_AUTHENTICATION_FAILED = "User authentication failed"
}

class ItemCorruptedException: Exception {
    constructor(): super(Errors.ITEM_CORRUPTED)
}

class DigestNotMatchingException: Exception {
    constructor(): super(Errors.DIGEST_NOT_MATCHING)
}


class AuthenticationFailedException: Exception {
    constructor(): super(Errors.USER_AUTHENTICATION_FAILED)
}